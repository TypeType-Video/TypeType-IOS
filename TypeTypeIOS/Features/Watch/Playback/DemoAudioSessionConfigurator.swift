import AVFoundation

enum DemoAudioSessionConfigurator {
  static func configure(backgroundAudio _: Bool) throws {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.playback, mode: .moviePlayback)
    try audioSession.setActive(true)
  }
}
