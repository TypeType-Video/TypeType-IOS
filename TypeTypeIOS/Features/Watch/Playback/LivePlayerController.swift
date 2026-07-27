import AVFoundation
import Foundation

@MainActor
final class LivePlayerController: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case failed(String)
  }

  let player = AVPlayer()

  @Published private(set) var state: State = .idle
  @Published private(set) var stream: LivePlaybackStream?
  @Published private(set) var preparation: LivePlaybackPreparation?
  @Published private(set) var position: TimeInterval = 0
  @Published private(set) var duration: TimeInterval = 0
  @Published var audioOnly = false
  @Published var selectedVideoItag: Int?
  @Published var selectedAudioTrackID: String?
  @Published var playbackRate: Float = 1

  private let video: LiveVideoItem
  private let service: LivePlaybackServiceProtocol?
  private let settingsService: LiveSettingsServiceProtocol
  private let historyService: LiveHistoryServiceProtocol
  private var settings = LiveSettings()
  private var loadTask: Task<Void, Never>?
  private var playbackServer: LivePlaybackHTTPServer?
  private var itemObservation: NSKeyValueObservation?
  private var playbackObservation: NSKeyValueObservation?
  private var endObservation: NSObjectProtocol?
  private var timeObserver: Any?
  private var didLoad = false
  private var pendingSeek: TimeInterval?
  private var lastHistoryProgress: Int64 = -1
  private var handledSponsorSegments: Set<String> = []
  private var sponsorMutedUntil: TimeInterval?

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.video = video
    service = dependencies.playbackService
    settingsService = dependencies.settingsService
    historyService = dependencies.historyService
    player.automaticallyWaitsToMinimizeStalling = true
    installPeriodicObserver()
  }

  deinit {
    playbackServer?.stop()
  }

  var availableVideoSources: [LivePlaybackVideoSource] {
    guard let stream else { return [] }
    return stream.allVideoSources
      .filter { $0.isSABR && $0.isAppleH264 }
      .sorted {
        if $0.height != $1.height { return $0.height < $1.height }
        return ($0.bitrate ?? 0) < ($1.bitrate ?? 0)
      }
  }

  var availableAudioSources: [LivePlaybackAudioSource] {
    guard let stream else { return [] }
    var seen: Set<String> = []
    return stream.audioStreams.filter {
      $0.isSABR && $0.isAppleAAC
        && seen.insert($0.id).inserted
    }
  }

  var transportLabel: String {
    guard let preparation else { return "Preparing playback" }
    if preparation.isSABR {
      return "SABR · \(preparation.video?.displayName ?? "audio")"
    }
    return "Native media"
  }

  var accessibilityStatus: String {
    switch state {
    case .idle: return "idle"
    case .loading: return "loading"
    case .ready: return "ready"
    case .playing: return "playing"
    case .paused: return "paused"
    case .failed: return "failed"
    }
  }

  func loadIfNeeded() async {
    guard !didLoad else { return }
    didLoad = true
    await load()
  }

  func retry() {
    loadTask?.cancel()
    didLoad = true
    loadTask = Task { [weak self] in
      await self?.load()
    }
  }

  func togglePlayback() {
    if player.timeControlStatus == .playing {
      player.pause()
    } else {
      player.playImmediately(atRate: playbackRate)
    }
  }

  func seek(to seconds: TimeInterval) {
    let bounded = min(max(seconds, 0), max(duration, 0))
    player.seek(
      to: CMTime(seconds: bounded, preferredTimescale: 600),
      toleranceBefore: .zero,
      toleranceAfter: .zero
    )
  }

  func selectVideoItag(_ itag: Int?) {
    guard selectedVideoItag != itag else { return }
    selectedVideoItag = itag
    restartAtCurrentPosition()
  }

  func selectAudioTrack(_ trackID: String?) {
    guard selectedAudioTrackID != trackID else { return }
    selectedAudioTrackID = trackID
    restartAtCurrentPosition()
  }

  func setAudioOnly(_ enabled: Bool) {
    guard audioOnly != enabled else { return }
    audioOnly = enabled
    restartAtCurrentPosition()
  }

  func setPlaybackRate(_ rate: Float) {
    playbackRate = min(max(rate, 0.25), 2)
    player.defaultRate = playbackRate
    if player.timeControlStatus == .playing {
      player.rate = playbackRate
    }
  }

  func flushHistory() {
    recordHistoryIfNeeded(force: true)
  }

  private func load() async {
    guard let service else {
      state = .failed(
        LivePlaybackFailure.unavailableService.localizedDescription
      )
      return
    }
    state = .loading
    handledSponsorSegments.removeAll()
    sponsorMutedUntil = nil
    do {
      async let settingsRequest = settingsService.settings()
      async let streamRequest = service.stream(for: video.url)
      settings = (try? await settingsRequest) ?? LiveSettings()
      let loadedStream = try await streamRequest
      guard !Task.isCancelled else { return }
      stream = loadedStream
      audioOnly = false
      selectedVideoItag = nil
      selectedAudioTrackID = settings.defaultAudioLanguage.isEmpty
        ? nil
        : loadedStream.audioStreams.first(where: {
          $0.audioLocale?.lowercased().hasPrefix(
            settings.defaultAudioLanguage.lowercased()
          ) == true
        })?.audioTrackID
      try await install(
        service.prepare(
          stream: loadedStream,
          preferences: preferences
        ),
        autoplay: true,
        seekOverride: nil
      )
    } catch is CancellationError {
      return
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  private func restartAtCurrentPosition() {
    guard let service, let stream else { return }
    let restartTime = position
    let wasPlaying = player.timeControlStatus == .playing
    state = .loading
    loadTask?.cancel()
    loadTask = Task { [weak self] in
      guard let self else { return }
      do {
        let preparation = try service.prepare(
          stream: stream,
          preferences: preferences
        )
        guard !Task.isCancelled else { return }
        try await install(
          preparation,
          autoplay: wasPlaying,
          seekOverride: restartTime
        )
      } catch {
        state = .failed(Self.message(for: error))
      }
    }
  }

  private var preferences: LivePlaybackPreferences {
    LivePlaybackPreferences(
      quality: settings.defaultQuality,
      videoItag: selectedVideoItag,
      audioTrackID: selectedAudioTrackID,
      audioOnly: audioOnly
    )
  }

  private func install(
    _ preparation: LivePlaybackPreparation,
    autoplay: Bool,
    seekOverride: TimeInterval?
  ) async throws {
    player.pause()
    playbackServer?.stop()
    playbackServer = nil
    self.preparation = preparation
    duration = TimeInterval(preparation.stream.duration)
    pendingSeek = {
      let requested = seekOverride ?? preparation.resumeTime
      guard duration > 0, requested < duration - 5 else { return 0 }
      return max(requested, 0)
    }()

    let assetURL: URL
    if preparation.usesAuthenticatedLoader,
      let service {
      let server = LivePlaybackHTTPServer(
        service: service,
        preparation: preparation,
        preferredSubtitleLanguage: settings.defaultSubtitleLanguage
      )
      assetURL = try await server.start()
      playbackServer = server
    } else {
      assetURL = preparation.assetURL
    }
    let asset = AVURLAsset(url: assetURL)
    let item = AVPlayerItem(asset: asset)
    item.preferredForwardBufferDuration = 20
    observe(item, autoplay: autoplay)
    player.replaceCurrentItem(with: item)
    player.defaultRate = playbackRate
    do {
      try DemoAudioSessionConfigurator.configure(
        backgroundAudio: true
      )
    } catch {
      state = .failed("The audio session could not be configured.")
    }
  }

  private func observe(
    _ item: AVPlayerItem,
    autoplay: Bool
  ) {
    if let endObservation {
      NotificationCenter.default.removeObserver(endObservation)
    }
    endObservation = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.state = .paused
        self?.recordHistoryIfNeeded(force: true)
      }
    }
    itemObservation = item.observe(
      \.status,
      options: [.initial, .new]
    ) { [weak self] item, _ in
      Task { @MainActor [weak self] in
        guard let self, player.currentItem === item else { return }
        switch item.status {
        case .unknown:
          state = .loading
        case .readyToPlay:
          duration = item.duration.seconds.isFinite
            ? item.duration.seconds
            : TimeInterval(preparation?.stream.duration ?? 0)
          configureSubtitles(for: item)
          let target = pendingSeek ?? 0
          pendingSeek = nil
          if target > 0 {
            player.seek(
              to: CMTime(
                seconds: target,
                preferredTimescale: 600
              ),
              toleranceBefore: .zero,
              toleranceAfter: .zero
            ) { [weak self] _ in
              Task { @MainActor [weak self] in
                guard let self else { return }
                if autoplay {
                  player.playImmediately(atRate: playbackRate)
                } else {
                  state = .ready
                }
              }
            }
          } else if autoplay {
            player.playImmediately(atRate: playbackRate)
          } else {
            state = .ready
          }
        case .failed:
          state = .failed(
            DemoPlaybackErrorFormatter.message(for: item.error)
          )
        @unknown default:
          state = .failed("The player reported an unknown state.")
        }
      }
    }
    playbackObservation = player.observe(
      \.timeControlStatus,
      options: [.new]
    ) { [weak self] player, _ in
      Task { @MainActor [weak self] in
        guard let self else { return }
        switch player.timeControlStatus {
        case .paused:
          if state == .playing { state = .paused }
        case .waitingToPlayAtSpecifiedRate:
          state = .loading
        case .playing:
          state = .playing
        @unknown default:
          break
        }
      }
    }
  }

  private func configureSubtitles(for item: AVPlayerItem) {
    let enablesSubtitles = settings.subtitlesEnabled
    let language = settings.defaultSubtitleLanguage
    Task { [weak self, weak item] in
      guard let self, let item else { return }
      guard let group = try? await item.asset.loadMediaSelectionGroup(
        for: .legible
      ) else {
        return
      }
      guard player.currentItem === item else { return }
      if !enablesSubtitles {
        item.select(nil, in: group)
        return
      }
      let option = group.options.first(where: { option in
        guard !language.isEmpty else { return false }
        return option.extendedLanguageTag?.lowercased().hasPrefix(
          language.lowercased()
        ) == true
      }) ?? group.defaultOption ?? group.options.first
      item.select(option, in: group)
    }
  }

  private func installPeriodicObserver() {
    timeObserver = player.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 1, preferredTimescale: 2),
      queue: .main
    ) { [weak self] time in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let seconds = time.seconds
        guard seconds.isFinite else { return }
        position = max(seconds, 0)
        updateSponsorBlock(at: position)
        recordHistoryIfNeeded(force: false)
      }
    }
  }

  private func updateSponsorBlock(at seconds: TimeInterval) {
    guard let segments = stream?.sponsorBlockSegments,
      settings.sponsorBlockMode == LiveSponsorBlockMode.autoSkip.rawValue
    else {
      return
    }
    if let sponsorMutedUntil {
      if seconds >= sponsorMutedUntil {
        player.isMuted = settings.muted
        self.sponsorMutedUntil = nil
      }
      return
    }
    let milliseconds = seconds * 1_000
    guard let segment = segments.first(where: {
      milliseconds >= $0.startTime
        && milliseconds < $0.endTime
        && !handledSponsorSegments.contains($0.id)
    }) else {
      return
    }
    handledSponsorSegments.insert(segment.id)
    let action = settings.sponsorBlockCategoryActions[segment.category]
      ?? segment.action
    guard action == "auto_skip" else { return }
    let duration = segment.endTime - segment.startTime
    guard duration > 0,
      duration < Double(stream?.duration ?? 0) * 900
    else {
      return
    }
    if settings.sponsorBlockMuteInsteadOfSkip {
      player.isMuted = true
      sponsorMutedUntil = segment.endTime / 1_000
    } else {
      seek(to: segment.endTime / 1_000)
    }
  }

  private func recordHistoryIfNeeded(force: Bool) {
    guard !settings.disableWatchHistory, position > 0 else { return }
    let progress = Int64(position.rounded(.down))
    guard force || lastHistoryProgress < 0
      || progress - lastHistoryProgress >= 15
    else {
      return
    }
    lastHistoryProgress = progress
    Task { [historyService, video] in
      _ = try? await historyService.add(
        video: video,
        progress: progress
      )
    }
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Playback could not be prepared."
  }
}
