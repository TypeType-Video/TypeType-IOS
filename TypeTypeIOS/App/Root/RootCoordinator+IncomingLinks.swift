import Foundation

extension RootCoordinator {
  func receiveIncomingURL(_ url: URL) {
    pendingIncomingURL = url
  }

  func consumeIncomingMediaLink() -> LiveIncomingMediaLink? {
    guard state == .authenticated,
      let pendingIncomingURL
    else {
      return nil
    }
    self.pendingIncomingURL = nil
    guard let destination = LiveMediaLinkResolver.destination(
      for: pendingIncomingURL,
      serverURL: selectedServer?.baseURL
    ) else {
      return nil
    }
    return LiveIncomingMediaLink(destination: destination)
  }
}
