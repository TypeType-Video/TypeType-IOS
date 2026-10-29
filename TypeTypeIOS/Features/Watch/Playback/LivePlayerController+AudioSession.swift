import AVFoundation

extension LivePlayerController {
  /// Off the main thread (setActive stalls the UI there), and awaited so the session is active before
  /// AVPlayer starts and activates it on its own.
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
    }.value
  }
}
