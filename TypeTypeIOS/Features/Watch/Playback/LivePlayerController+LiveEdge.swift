import AVFoundation

extension LivePlayerController {
  // AVPlayer holds a live some way back from the newest segment, as far as the stream recommends: only a gap well
  // beyond that offset means the viewer fell behind.
  static let liveEdgeSlack: TimeInterval = 10

  var isBehindLiveEdge: Bool {
    guard isLiveStream, nativePlayback == nil, let item = player.currentItem,
      let window = item.seekableTimeRanges.last?.timeRangeValue
    else { return false }
    let lag = window.end.seconds - item.currentTime().seconds
    return lag.isFinite && lag > Self.liveOffset(of: item) + Self.liveEdgeSlack
  }

  func goToLiveEdge() {
    guard let item = player.currentItem, let window = item.seekableTimeRanges.last?.timeRangeValue,
      window.duration.seconds > 0
    else {
      return retry()
    }
    AppLogger.playback.notice("live: back to the live edge")
    let target = window.end - CMTime(seconds: Self.liveOffset(of: item), preferredTimescale: 600)
    player.seek(to: CMTimeMaximum(target, window.start))
    resume()
  }

  private static func liveOffset(of item: AVPlayerItem) -> TimeInterval {
    let offset = item.recommendedTimeOffsetFromLive.seconds
    return offset.isFinite && offset > 0 ? offset : 6
  }
}
