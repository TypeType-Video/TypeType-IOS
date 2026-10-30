import AVFoundation
import Combine
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

  @Published var state: State = .idle {
    didSet { releaseExtrasIfStarted() }
  }
  @Published var extrasReleased = false
  var firstFrameJobs: [() -> Void] = []
  @Published var stream: LivePlaybackStream?
  @Published var nativePlayback: LiveNativePlayback?
  @Published var nativeSubtitleCues: [LiveSubtitleCue] = []
  var nativeSubtitlesTask: Task<Void, Never>?
  var nativeFallbackUsed = false
  @Published var isPresentingFullscreen = false
  lazy var fullscreen = LiveNativeFullscreenPresenter(controller: self)
  @Published var isVideoDocked = false
  @Published var isOfflineContent = false
  @Published var preparation: LivePlaybackPreparation?
  @Published var lastStartupMilliseconds: Int?
  var startupTrace = LivePlaybackStartupTrace()
  var metadataTask: Task<Void, Never>?
  // Bumped by each load or restart; an older, slower load never installs.
  var loadGeneration = 0
  var startupWatchdog: Task<Void, Never>?
  var startupRetryUsed = false
  var sabrOfflineRetries = 0
  @Published var isLoadingFullMetadata = false
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
  var onNearEnd: (() -> Void)?
  var didNotifyNearEnd = false

  let video: LiveVideoItem
  let initialAutoplay: Bool
  let pictureInPicture = LivePictureInPictureDriver()
  var isPlayerSurfaceFullyVisible = true
  // Set on stop or close: pending async work must never start playback afterwards.
  var isTornDown = false
  let service: LivePlaybackServiceProtocol?
  let settingsService: LiveSettingsServiceProtocol
  let historyService: LiveHistoryServiceProtocol
  let watchProgress: LiveWatchProgressStore
  let appPreferences: LiveAppPreferencesStore
  let orientationLock: LiveOrientationLock
  let playbackSessionReporter: LivePlaybackSessionReporter
  let bulletCommentStore = LiveBulletCommentStore()
  @Published var settings = LiveSettings()
  var loadTask: Task<Void, Never>?
  var seekTask: Task<Void, Never>?
  var playbackServer: LivePlaybackHTTPServer?
  var itemObservation: NSKeyValueObservation?
  var bulletCommentPreferencesObservation: AnyCancellable?
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
    watchProgress = dependencies.watchProgress
    appPreferences = dependencies.appPreferences
    orientationLock = dependencies.orientationLock
    playbackSessionReporter = LivePlaybackSessionReporter(
      service: dependencies.sessionActivityService
    )
    let defaults = UserDefaults.standard
    let initialPreferences = appPreferences.preferences
    audioOnly = initialPreferences.playerAudioOnlyPlayback
    Self.moveLegacyBulletCommentChoices(into: appPreferences, from: defaults)
    observeBulletCommentPreferences()
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
    if case let NetworkError.statusCode(code, message)? = error as? NetworkError,
      (400..<500).contains(code), code != 401,
      let message = message?.trimmingCharacters(in: .whitespacesAndNewlines),
      !message.isEmpty {
      return message
    }
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
