import AVFoundation

enum DemoAudioSessionConfigurator {
  /// Runs the audio session work off the main thread and completes before
  /// callers continue, so playback never races an inactive session.
  static func configure(backgroundAudio _: Bool) async throws {
    try await Task.detached(priority: .userInitiated) {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .moviePlayback)
      try audioSession.setActive(true)
    }.value
  }
}
