import OSLog

extension Logger {
  func failure(_ action: String, _ cause: Error) {
    error("\(action, privacy: .public) failed: \(String(describing: cause), privacy: .public)")
  }
}
