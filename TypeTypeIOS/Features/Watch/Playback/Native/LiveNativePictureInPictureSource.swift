import AVKit

// PiP asks synchronously and maybe off the main actor: answers come from a snapshot kept current.
final class LiveNativePictureInPictureSource: NSObject, AVPictureInPictureSampleBufferPlaybackDelegate,
  @unchecked Sendable
{
  private let lock = NSLock()
  private var duration: TimeInterval = 0
  private var paused = true
  private let setPlaying: @Sendable (Bool) -> Void
  private let skip: @Sendable (TimeInterval) -> Void

  init(setPlaying: @escaping @Sendable (Bool) -> Void, skip: @escaping @Sendable (TimeInterval) -> Void) {
    self.setPlaying = setPlaying
    self.skip = skip
  }

  func update(duration: TimeInterval, paused: Bool) {
    lock.withLock {
      self.duration = duration
      self.paused = paused
    }
  }

  func pictureInPictureController(_ controller: AVPictureInPictureController, setPlaying playing: Bool) {
    setPlaying(playing)
  }

  func pictureInPictureControllerTimeRangeForPlayback(_ controller: AVPictureInPictureController) -> CMTimeRange {
    let seconds = lock.withLock { duration }
    return CMTimeRange(start: .zero, duration: CMTime(seconds: max(seconds, 0), preferredTimescale: 600))
  }

  func pictureInPictureControllerIsPlaybackPaused(_ controller: AVPictureInPictureController) -> Bool {
    lock.withLock { paused }
  }

  func pictureInPictureController(
    _ controller: AVPictureInPictureController,
    didTransitionToRenderSize newRenderSize: CMVideoDimensions
  ) {}

  func pictureInPictureController(
    _ controller: AVPictureInPictureController,
    skipByInterval skipInterval: CMTime,
    completion completionHandler: @escaping () -> Void
  ) {
    skip(skipInterval.seconds)
    completionHandler()
  }
}
