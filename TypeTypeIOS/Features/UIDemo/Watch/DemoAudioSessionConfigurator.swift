import AVFoundation

enum DemoAudioSessionConfigurator {
  static func configure(backgroundAudio enabled: Bool) throws {
    let audioSession = AVAudioSession.sharedInstance()
    if enabled {
      try audioSession.setCategory(.playback, mode: .moviePlayback)
    } else {
      try audioSession.setCategory(
        .ambient,
        mode: .default,
        options: [.mixWithOthers]
      )
    }
    try audioSession.setActive(true)
  }
}
