import AVFoundation

extension LivePlayerController {
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
