import Foundation

extension LivePlaybackPreferences {
  static func initial(
    for stream: LivePlaybackStream,
    settings: LiveSettings,
    audioOnly: Bool,
    preferredCodec: String
  ) -> LivePlaybackPreferences {
    let language = settings.defaultAudioLanguage.lowercased()
    let preferredAudio = language.isEmpty
      ? nil
      : stream.audioStreams.first {
        $0.audioLocale?.lowercased().hasPrefix(language) == true
      }
    return LivePlaybackPreferences(
      quality: settings.defaultQuality,
      preferredCodec: preferredCodec,
      videoItag: nil,
      videoSourceID: nil,
      audioTrackID: preferredAudio?.audioTrackID,
      audioSourceID: preferredAudio?.id,
      audioOnly: audioOnly
    )
  }
}

extension LivePlaybackPreparation {
  static func startTime(
    requested: TimeInterval,
    duration: TimeInterval
  ) -> TimeInterval {
    guard duration > 0, requested < duration - 5 else { return 0 }
    return max(requested, 0)
  }
}
