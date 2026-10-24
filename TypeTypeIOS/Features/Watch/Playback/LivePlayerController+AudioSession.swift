import AVFoundation

extension LivePlayerController {
  /// Audio session work runs off the main thread: setCategory/setActive
  /// there caused the system's UI-unresponsiveness warnings (and stalls).
  nonisolated func configureAudioSession() {
    Task.detached(priority: .userInitiated) {
      let audioSession = AVAudioSession.sharedInstance()
      do {
        try audioSession.setCategory(
          .playback,
          mode: .moviePlayback
        )
        try audioSession.setActive(true)
      } catch {
        AppLogger.app.error(
          "Playback audio session setup failed: \(error.localizedDescription, privacy: .public)"
        )
      }
    }
  }
}
