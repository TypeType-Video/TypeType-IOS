import AVFoundation
import Combine

extension AVPlayer {
  @MainActor
  func resumeEachPause(for window: Duration, _ onPause: @escaping @MainActor () -> Void) async {
    await withTaskGroup(of: Void.self) { group in
      group.addTask { @MainActor in
        for await status in self.publisher(for: \.timeControlStatus).values where status == .paused {
          onPause()
        }
      }
      group.addTask {
        try? await Task.sleep(for: window)
      }
      await group.next()
      group.cancelAll()
    }
  }
}
