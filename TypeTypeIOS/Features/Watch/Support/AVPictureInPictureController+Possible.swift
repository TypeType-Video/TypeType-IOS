import AVKit
import Combine

extension AVPictureInPictureController {
  @MainActor
  func becomesPossible(within timeout: Duration) async -> Bool {
    if isPictureInPicturePossible { return true }
    return await withTaskGroup(of: Bool.self) { group in
      group.addTask { @MainActor in
        for await possible in self.publisher(for: \.isPictureInPicturePossible).values where possible {
          return true
        }
        return false
      }
      group.addTask {
        try? await Task.sleep(for: timeout)
        return false
      }
      let possible = await group.next() ?? false
      group.cancelAll()
      return possible
    }
  }
}
