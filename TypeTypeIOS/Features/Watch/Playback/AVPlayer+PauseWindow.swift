import AVFoundation
import Combine

extension AVPlayer {
  /// Calls `onPause` each time the player is paused, now or within `window`. AVKit pauses the
  /// player while its view changes windows (full screen, Picture in Picture, a dismantled page).
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
