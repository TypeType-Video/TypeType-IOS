import AVFoundation
import Foundation

extension LivePlayerController {
  func providerComposition(
    videoURL: URL,
    audioURL: URL,
    fallbackDuration: TimeInterval
  ) async throws -> AVMutableComposition {
    let options: [String: Any] = [
      AVURLAssetHTTPUserAgentKey:
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)"
        + " AppleWebKit/605.1.15 Mobile/15E148",
    ]
    let videoAsset = AVURLAsset(url: videoURL, options: options)
    let audioAsset = AVURLAsset(url: audioURL, options: options)

    let videoTracks = try await videoAsset.loadTracks(
      withMediaType: .video
    )
    let audioTracks = try await audioAsset.loadTracks(
      withMediaType: .audio
    )
    guard let sourceVideo = videoTracks.first,
      let sourceAudio = audioTracks.first
    else {
      throw LivePlaybackFailure.noPlayableSource
    }

    let videoDuration = try await videoAsset.load(.duration)
    let audioDuration = try await audioAsset.load(.duration)
    let resolvedDuration = providerDuration(
      video: videoDuration,
      audio: audioDuration,
      fallback: fallbackDuration
    )
    let range = CMTimeRange(start: .zero, duration: resolvedDuration)

    let composition = AVMutableComposition()
    guard
      let videoTrack = composition.addMutableTrack(
        withMediaType: .video,
        preferredTrackID: kCMPersistentTrackID_Invalid
      ),
      let audioTrack = composition.addMutableTrack(
        withMediaType: .audio,
        preferredTrackID: kCMPersistentTrackID_Invalid
      )
    else {
      throw LivePlaybackFailure.noPlayableSource
    }

    try videoTrack.insertTimeRange(range, of: sourceVideo, at: .zero)
    try audioTrack.insertTimeRange(range, of: sourceAudio, at: .zero)
    videoTrack.preferredTransform = try await sourceVideo.load(
      .preferredTransform
    )
    return composition
  }

  private func providerDuration(
    video: CMTime,
    audio: CMTime,
    fallback: TimeInterval
  ) -> CMTime {
    let valid = [video, audio].filter {
      $0.isNumeric && $0.seconds.isFinite && $0.seconds > 0
    }
    if let shortest = valid.min(by: {
      CMTimeCompare($0, $1) < 0
    }) {
      return shortest
    }
    return CMTime(
      seconds: max(fallback, 1),
      preferredTimescale: 600
    )
  }
}
