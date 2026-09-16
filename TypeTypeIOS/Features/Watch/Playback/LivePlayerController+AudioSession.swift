import AVFoundation

extension LivePlayerController {
  func configureAudioSession() {
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
