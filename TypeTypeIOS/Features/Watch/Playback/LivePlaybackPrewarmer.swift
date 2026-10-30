import Foundation

@MainActor
final class LivePlaybackPrewarmer {
  private let service: LivePlaybackServiceProtocol
  private let settingsService: LiveSettingsServiceProtocol
  private let historyService: LiveHistoryServiceProtocol
  private let appPreferences: LiveAppPreferencesStore

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

  func prewarm(_ video: LiveVideoItem) {
    guard !video.isLive else { return }
    let url = video.url
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
