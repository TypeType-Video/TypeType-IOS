import Foundation

@MainActor
final class LivePlaybackCoordinator: ObservableObject {
  enum Presentation: Equatable {
    case hidden
    case mini
    case expanded
  }

  typealias PlayerFactory = (
    _ video: LiveVideoItem,
    _ autoplay: Bool
  ) -> LivePlayerController

  @Published var currentVideo: LiveVideoItem?
  @Published var controller: LivePlayerController?
  @Published var presentation = Presentation.hidden
  @Published var queue = LivePlaybackQueueSnapshot.empty
  @Published var sleepTimer = LivePlaybackSleepTimerState()
  @Published var autoplayCountdownRemaining: Int?

  let settingsService: LiveSettingsServiceProtocol
  let appPreferences: LiveAppPreferencesStore
  let queueStore: LivePlaybackQueueStore
  let scopeProvider: () -> LivePlaybackScope?
  let playerFactory: PlayerFactory
  var activeScope: LivePlaybackScope?
  var restoredScope: LivePlaybackScope?
  var persistenceEnabled = false
  var playbackGeneration = 0
  var sleepTimerTask: Task<Void, Never>?
  var autoplayCountdownTask: Task<Void, Never>?
  var pendingAutoplay: LivePendingAutoplay?
  var prewarmer: LivePlaybackPrewarmer?
  var hiddenVideos: LiveHiddenVideos?

  init(
    settingsService: LiveSettingsServiceProtocol,
    appPreferences: LiveAppPreferencesStore,
    queueStore: LivePlaybackQueueStore = LivePlaybackQueueStore(),
    scopeProvider: @escaping () -> LivePlaybackScope?,
    playerFactory: @escaping PlayerFactory
  ) {
    self.settingsService = settingsService
    self.appPreferences = appPreferences
    self.queueStore = queueStore
    self.scopeProvider = scopeProvider
    self.playerFactory = playerFactory
  }

  var hasActivePlayback: Bool {
    currentVideo != nil && controller != nil
  }

  var showsMiniPlayer: Bool {
    hasActivePlayback && presentation == .mini
   && !(controller?.pictureInPicture.isEngaged ?? false)
    && !(controller?.pictureInPicture.isPendingStart ?? false)
  }

  func restoreIfNeeded() async {
    guard let scope = scopeProvider(),
      restoredScope != scope
    else {
      return
    }
    endRuntime(preservingPersistedQueue: true)
    activeScope = scope
    restoredScope = scope

    let settings = try? await settingsService.settings()
    guard scopeProvider() == scope, activeScope == scope else { return }
    applyPersistencePolicy(
      enabled: !(settings ?? LiveSettings()).disableWatchHistory
    )
    guard persistenceEnabled,
      controller == nil,
      let stored = queueStore.load(for: scope)
    else {
      return
    }
    queue = stored
    guard let video = stored.current else {
      queueStore.clear(scope)
      queue = .empty
      return
    }
    presentation = .mini
    replacePlayback(with: video, autoplay: false)
  }

  func open(_ video: LiveVideoItem) {
    guard isPlayable(video) else { return }
    adoptCurrentScopeIfNeeded()
    if currentVideo?.url == video.url, controller != nil {
      presentation = .expanded
      return
    }
    clearQueue()
    presentation = .expanded
    replacePlayback(with: video, autoplay: true)
  }

  // Downloads play in the same player as online videos: one controller, so the mini player, PiP and background audio
  // never end up with two players fighting over the page.
  func open(offline item: LiveOfflinePlaybackItem) {
    adoptCurrentScopeIfNeeded()
    if currentVideo?.url == item.watchVideo.url, controller?.isOfflineContent == true {
      presentation = .expanded
      return
    }
    clearQueue()
    presentation = .expanded
    replacePlayback(with: item.watchVideo, autoplay: true, offline: item)
  }

  @discardableResult
  func startQueue(
    title: String,
    videos: [LiveVideoItem],
    shuffle: Bool
  ) -> LiveVideoItem? {
    adoptCurrentScopeIfNeeded()
    var seen: Set<String> = []
    let distinct = videos.filter {
      isPlayable($0) && seen.insert($0.url).inserted
    }
    let ordered = shuffle ? distinct.shuffled() : distinct
    guard let first = ordered.first else { return nil }
    queue = LivePlaybackQueueSnapshot(
      title: title.trimmingCharacters(in: .whitespacesAndNewlines),
      videos: ordered,
      currentIndex: 0,
      repeatMode: .off,
      updatedAt: .now
    )
    persistQueue()
    presentation = .expanded
    replacePlayback(with: first, autoplay: true)
    return first
  }

  @discardableResult
  func enqueue(
    _ video: LiveVideoItem,
    playNext: Bool
  ) -> LivePlaybackQueueMutationResult {
    guard isPlayable(video) else { return .invalidVideo }
    guard let currentVideo, controller != nil else {
      return .noActivePlayback
    }
    adoptCurrentScopeIfNeeded()
    if video.url == currentVideo.url {
      return .alreadyPlaying
    }

    let result = queue.enqueue(
      video,
      current: currentVideo,
      playNext: playNext
    )
    if result == .added || result == .moved {
      touchAndPersist()
    }
    return result
  }
}
