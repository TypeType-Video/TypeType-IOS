import AVFoundation

extension LivePlayerController {
  /// Audio session work runs off the main thread: setCategory/setActive
  /// there caused the system's UI-unresponsiveness warnings (and stalls).
  /// Awaited by the caller so the session is active before AVPlayer starts;
  /// otherwise AVPlayer's implicit activation races this and warns itself.
  nonisolated func configureAudioSession() async {
    await Task.detached(priority: .userInitiated) {
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
