import Foundation

extension LivePlayerController {
  func afterFirstFrame(_ job: @escaping () -> Void) {
    if extrasReleased {
      job()
    } else {
      firstFrameJobs.append(job)
    }
  }

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
