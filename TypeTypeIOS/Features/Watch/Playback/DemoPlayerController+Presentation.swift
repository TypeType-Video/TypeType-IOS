import Foundation

extension DemoPlayerController {
  func resumeAfterPresentationChange(if wasPlaying: Bool) {
    guard wasPlaying else { return }
    Task { @MainActor [weak self] in
      await Task.yield()
      self?.start()
    }
  }
}
