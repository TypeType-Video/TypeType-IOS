import OSLog

extension Logger {
  // For best-effort calls: the UI moves on, but a failure that loses the user's change still leaves a trace.
  func failure(_ action: String, _ cause: Error) {
    error("\(action, privacy: .public) failed: \(String(describing: cause), privacy: .public)")
  }
}
