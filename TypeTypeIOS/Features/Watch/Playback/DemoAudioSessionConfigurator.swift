import AVFoundation

enum DemoAudioSessionConfigurator {
  static func configure(backgroundAudio _: Bool) async throws {
    try await Task.detached(priority: .userInitiated) {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .moviePlayback)
      try audioSession.setActive(true)
    }.value
  }
}
