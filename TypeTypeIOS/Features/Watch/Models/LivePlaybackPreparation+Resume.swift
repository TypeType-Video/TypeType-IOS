import Foundation

extension LivePlaybackPreparation {
  func resuming(at seconds: TimeInterval) -> LivePlaybackPreparation {
    LivePlaybackPreparation(
      stream: stream,
      assetURL: assetURL,
      usesAuthenticatedLoader: usesAuthenticatedLoader,
      video: video,
      audio: audio,
      providerPlayback: providerPlayback,
      subtitles: subtitles,
      resumeTime: max(seconds, 0),
      isSABR: isSABR,
      audioOnly: audioOnly
    )
  }
}
