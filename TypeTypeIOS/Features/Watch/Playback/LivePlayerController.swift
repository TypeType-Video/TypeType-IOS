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

  @Published var state: State = .idle
  @Published var stream: LivePlaybackStream?
  @Published var preparation: LivePlaybackPreparation?
  @Published var position: TimeInterval = 0
  @Published var duration: TimeInterval = 0
  @Published var audioOnly = false
  @Published var selectedVideoItag: Int?
  @Published var selectedVideoSourceID: String?
  @Published var selectedAudioTrackID: String?
  @Published var selectedAudioSourceID: String?
  @Published var playbackRate: Float = 1
  @Published var imageMode = LivePlayerImageMode.fit
  @Published var autoplayEnabled = true
  @Published var loopsPlayback = false
  @Published var subtitlesEnabled = false
  @Published var selectedSubtitleLanguage = ""
  @Published var sponsorBlockEnabled = true
  @Published var sponsorBlockMode = LiveSponsorBlockMode.autoSkip.rawValue
  @Published var sponsorBlockCategoryActions: [String: String] = [:]
  @Published var sponsorBlockMinimumDuration = 0
  @Published var sponsorBlockMuteInsteadOfSkip = false
  @Published var sponsorBlockShowCurrentSegment = true
  @Published var sponsorBlockShowChapters = false
  @Published var sponsorBlockShowFullVideoLabels = true
  @Published var sponsorBlockManualSkipOnFullVideo = true
  @Published var sponsorBlockSkipNonMusicOnlyOnMusicVideos = false
  @Published var muted = false
  @Published var bulletCommentsEnabled = false
  @Published var bulletCommentSpeed = 1.0
  @Published var bulletCommentSize = 1.0

  var onPlaybackEnded: (() -> Void)?
  var onMetadataResolved: ((LiveVideoItem) -> Void)?

  let video: LiveVideoItem
  let initialAutoplay: Bool
  let pictureInPicture = LivePictureInPictureDriver()
  /// Whether the player surface sits at the top of the page (page not
  /// scrolled). Gates the pull-down-to-mini gesture.
  var isPlayerSurfaceFullyVisible = true
  /// Mirror of the AVKit chrome visibility; overlay buttons bind to this.
  @Published var playerChromeVisible = true
  let service: LivePlaybackServiceProtocol?
  let settingsService: LiveSettingsServiceProtocol
  let historyService: LiveHistoryServiceProtocol
  let playbackSessionReporter: LivePlaybackSessionReporter
  let bulletCommentStore = LiveBulletCommentStore()
  @Published var settings = LiveSettings()
  var loadTask: Task<Void, Never>?
  var seekTask: Task<Void, Never>?
  var playbackServer: LivePlaybackHTTPServer?
  var itemObservation: NSKeyValueObservation?
  var playbackObservation: NSKeyValueObservation?
  var endObservation: NSObjectProtocol?
  var timeObserver: Any?
  var didLoad = false
  var pendingSeek: TimeInterval?
  var playbackTimeOffset: TimeInterval = 0
  var lastHistoryProgress: Int64 = -1
  var didRecordHistoryEvent = false
  var playbackSessionProgressTask: Task<Void, Never>?
  var presentationResumeTask: Task<Void, Never>?
  var sabrStallRecoveryTask: Task<Void, Never>?
  var sabrRecoveryBudgetResetTask: Task<Void, Never>?
  var sabrStallRecoveryCount = 0
  var bulletCommentsTask: Task<Void, Never>?
  var bulletCommentsLoadGeneration = 0
  var bulletCommentStateRevision = 0
  var handledSponsorSegments: Set<String> = []
  var sponsorMutedRange: Range<TimeInterval>?
  var attemptedProviderVideoSourceIDs: Set<String> = []
  var attemptedProviderAudioSourceIDs: Set<String> = []
  var providerRecoveryInProgress = false
  var providerRecoveryResumeTime: TimeInterval = 0
  var providerRecoveryDesiredAutoplay = false

  init(
    video: LiveVideoItem,
    dependencies: AppDependencies,
    autoplay: Bool = true
  ) {
    self.video = video
    initialAutoplay = autoplay
    service = dependencies.playbackService
    settingsService = dependencies.settingsService
    historyService = dependencies.historyService
    playbackSessionReporter = LivePlaybackSessionReporter(
      service: dependencies.sessionActivityService
    )
    let defaults = UserDefaults.standard
    let appPreferences = LiveAppPreferencesStore.shared.preferences
    audioOnly = appPreferences.playerAudioOnlyPlayback
    autoplayEnabled = appPreferences.playerAutoplayEnabled
    let defaultDanmakuEnabled = appPreferences.danmakuEnabled
    bulletCommentsEnabled = defaults.object(
      forKey: Self.bulletCommentsEnabledKey
    ) == nil
      ? defaultDanmakuEnabled
      : defaults.bool(forKey: Self.bulletCommentsEnabledKey)
    let storedSpeed = defaults.object(
      forKey: Self.bulletCommentSpeedKey
    ) == nil ? 1 : defaults.double(forKey: Self.bulletCommentSpeedKey)
    bulletCommentSpeed = min(max(storedSpeed, 0.5), 2)
    let storedSize = defaults.object(
      forKey: Self.bulletCommentSizeKey
    ) == nil ? 1 : defaults.double(forKey: Self.bulletCommentSizeKey)
    bulletCommentSize = min(max(storedSize, 0.5), 2)
    player.automaticallyWaitsToMinimizeStalling = true
    installPeriodicObserver()
  }

  deinit {
    playbackSessionProgressTask?.cancel()
    presentationResumeTask?.cancel()
    sabrStallRecoveryTask?.cancel()
    sabrRecoveryBudgetResetTask?.cancel()
    bulletCommentsTask?.cancel()
    playbackServer?.stop()
    let reporter = playbackSessionReporter
    Task { @MainActor in
      reporter.stop()
    }
  }

  var availableVideoSources: [LivePlaybackVideoSource] {
    guard let stream else { return [] }
    let sabr = stream.allVideoSources.filter {
      $0.isSABR && $0.isAppleH264
    }
    let compatible = sabr.isEmpty
      ? stream.allVideoSources.filter {
        !$0.isSABR && $0.isAppleProviderVideo
      }
      : sabr
    var seen: Set<String> = []
    return compatible
      .filter { seen.insert($0.selectionID).inserted }
      .sorted {
        if $0.height != $1.height { return $0.height < $1.height }
        return ($0.bitrate ?? 0) < ($1.bitrate ?? 0)
      }
  }

  var availableAudioSources: [LivePlaybackAudioSource] {
    guard let stream else { return [] }
    let sabr = stream.audioStreams.filter {
      $0.isSABR && $0.isAppleAAC
    }
    let compatible = sabr.isEmpty
      ? stream.audioStreams.filter {
        !$0.isSABR && $0.isAppleProviderAudio
      }
      : sabr
    var seen: Set<String> = []
    return compatible.filter {
      seen.insert($0.id).inserted
    }
  }

  var transportLabel: String {
    guard let preparation else { return "Preparing playback" }
    if preparation.isSABR {
      return preparation.audioOnly
        ? "SABR · audio"
        : "SABR · \(preparation.video?.displayName ?? "automatic")"
    }
    if preparation.providerPlayback != nil {
      return "Native · \(preparation.video?.displayName ?? "automatic")"
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

  var bulletComments: [LiveBulletComment] {
    bulletCommentStore.state.comments
  }

  var bulletCommentsLoading: Bool {
    bulletCommentStore.state.isLoading
  }

  static func message(for error: Error) -> String {
    if let description = (error as? LocalizedError)?.errorDescription,
      !description.isEmpty {
      return description
    }
    let description = (error as NSError).localizedDescription
    return description.isEmpty
      ? "Playback could not be prepared."
      : description
  }

  static func logPreparationFailure(_ error: Error) {
    let failure = error as NSError
    AppLogger.app.error(
      "Playback preparation failed: \(failure.domain, privacy: .public) \(failure.code) \(failure.localizedDescription, privacy: .public)"
    )
    if let underlying = failure.userInfo[
      NSUnderlyingErrorKey
    ] as? NSError {
      AppLogger.app.error(
        "Underlying playback failure: \(underlying.domain, privacy: .public) \(underlying.code) \(underlying.localizedDescription, privacy: .public)"
      )
    }
  }
}
