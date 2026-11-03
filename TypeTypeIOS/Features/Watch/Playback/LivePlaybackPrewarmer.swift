import Foundation

@MainActor
final class LivePlaybackPrewarmer {
  private let service: LivePlaybackServiceProtocol
  private let settingsService: LiveSettingsServiceProtocol
  private let historyService: LiveHistoryServiceProtocol
  private let appPreferences: LiveAppPreferencesStore
  private var prewarmedAt: [String: ContinuousClock.Instant] = [:]
  // The video already loaded in the player: preparing it again would only open a session nobody takes.
  var currentVideoURL: (() -> String?)?
  // Both cards the scroll rests on get a whole session: the reader may tap either, and only a prepared session
  // removes the seconds the instance spends creating one.
  lazy var settledCards = LiveSettledCardPrefetch { [weak self] video in
    self?.prewarm(video)
  }

  init(
    service: LivePlaybackServiceProtocol,
    settingsService: LiveSettingsServiceProtocol,
    historyService: LiveHistoryServiceProtocol,
    appPreferences: LiveAppPreferencesStore
  ) {
    self.service = service
    self.settingsService = settingsService
    self.historyService = historyService
    self.appPreferences = appPreferences
  }

  // The instance keeps a prewarmed session for 60 s: asking again inside that window only opens a second one.
  static let prewarmReuseWindow: Duration = .seconds(50)

  func prewarm(_ video: LiveVideoItem) {
    guard !video.isLive, currentVideoURL?() != video.url else { return }
    let url = video.url
    let now = ContinuousClock.now
    if let last = prewarmedAt[url], now - last < Self.prewarmReuseWindow { return }
    prewarmedAt = prewarmedAt.filter { now - $0.value < Self.prewarmReuseWindow }
    prewarmedAt[url] = now
    let service = service
    let settingsService = settingsService
    let historyService = historyService
    let appPreferences = appPreferences.preferences
    service.preconnectMedia()
    Task(priority: .userInitiated) {
      async let streamRequest = service.playbackStream(for: url)
      async let settingsRequest = settingsService.settings()
      async let progressRequest = historyService.progress(videoURL: url)
      guard let stream = try? await streamRequest, !stream.isLive else { return }
      let settings = (try? await settingsRequest) ?? LiveSettings()
      let savedMS = (try? await progressRequest) ?? nil
      let preferences = LivePlaybackPreferences.initial(
        for: stream,
        settings: settings,
        audioOnly: appPreferences.playerAudioOnlyPlayback,
        preferredCodec: appPreferences.playerPreferredCodec
      )
      guard var preparation = try? service.prepare(
        stream: stream,
        sourceURL: url,
        preferences: preferences
      ) else {
        return
      }
      if let savedMS, savedMS > 0 {
        preparation = preparation.resuming(at: TimeInterval(savedMS) / 1_000)
      }
      guard preparation.isSABR,
        let videoSource = preparation.video,
        let audioSource = preparation.audio
      else {
        return
      }
      let start = LivePlaybackPreparation.startTime(
        requested: preparation.resumeTime,
        duration: TimeInterval(stream.duration)
      )
      let startMS = Int64(start * 1_000)
      await service.prewarmSABRPlayback(
        videoID: stream.id,
        request: LiveSABRPlaybackRequest(
          videoItag: videoSource.itag,
          audioItag: audioSource.itag,
          audioTrackID: audioSource.audioTrackID,
          startTimeMS: startMS,
          playerTimeMS: startMS,
          audioOnly: preparation.audioOnly,
          isLive: false
        )
      )
    }
  }
}
