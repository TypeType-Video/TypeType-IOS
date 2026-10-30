import Foundation

extension LivePlaybackPreferences {
  // The prewarm and the real start must send the same plan, or the server opens a second session.
  static func initial(
    for stream: LivePlaybackStream,
    settings: LiveSettings,
    audioOnly: Bool,
    preferredCodec: String
  ) -> LivePlaybackPreferences {
    let preferredAudio = initialAudio(
      in: stream,
      language: settings.defaultAudioLanguage,
      preferOriginal: settings.preferOriginalLanguage
    )
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

extension LivePlaybackPreferences {
  static func initialAudio(
    in stream: LivePlaybackStream,
    language: String,
    preferOriginal: Bool
  ) -> LivePlaybackAudioSource? {
    // Only what the audio track menu offers: an Opus pick there leaves the menu showing an empty value.
    let tracks = stream.playableAudioSources
    if preferOriginal {
      return tracks.first { $0.audioTrackID != nil && $0.audioTrackID == stream.originalAudioTrackID }
        ?? tracks.first { $0.isOriginal && $0.audioTrackID != nil }
    }
    let code = language.lowercased()
    guard !code.isEmpty else { return nil }
    return tracks.first { $0.audioLocale?.lowercased().hasPrefix(code) == true }
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
