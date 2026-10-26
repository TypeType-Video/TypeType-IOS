import Foundation

extension LivePlayerController {
  /// Runs `job` once the video has started; before that, only requests that
  /// start playback may use the network.
  func afterFirstFrame(_ job: @escaping () -> Void) {
    if extrasReleased {
      job()
    } else {
      firstFrameJobs.append(job)
    }
  }

  /// A start ends with the first frame, a paused ready item (no autoplay), or
  /// a failure; each one releases the waiting work.
  func releaseExtrasIfStarted() {
    guard !extrasReleased else { return }
    switch state {
    case .idle, .loading:
      return
    case .ready, .playing, .paused, .failed:
      break
    }
    extrasReleased = true
    let jobs = firstFrameJobs
    firstFrameJobs = []
    jobs.forEach { $0() }
  }
}
