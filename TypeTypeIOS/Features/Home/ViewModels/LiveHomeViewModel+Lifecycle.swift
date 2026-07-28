extension LiveHomeViewModel {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
  }

  func loadIfNeeded() async {
    guard state == .idle else { return }
    await reload()
  }
}
