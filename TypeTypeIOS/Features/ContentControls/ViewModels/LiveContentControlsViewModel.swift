import Foundation

@MainActor
final class LiveContentControlsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published var kind = LiveContentControlKind.blockedChannels
  @Published private(set) var state = State.idle
  @Published private(set) var items: [LiveContentControlItem] = []
  @Published private(set) var isBusy = false
  @Published private(set) var errorMessage: String?

  let service: LiveContentControlsServiceProtocol
  private let hiddenVideos: LiveHiddenVideos?

  init(
    service: LiveContentControlsServiceProtocol,
    kind: LiveContentControlKind = .blockedChannels,
    hiddenVideos: LiveHiddenVideos? = nil
  ) {
    self.service = service
    self.kind = kind
    self.hiddenVideos = hiddenVideos
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      items = try await service.items(kind: kind)
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func add(
    url: String,
    name: String,
    global: Bool
  ) async -> Bool {
    guard !isBusy else { return false }
    isBusy = true
    defer { isBusy = false }
    do {
      let item = try await service.add(
        kind: kind,
        item: LiveContentControlItem(
          url: url.trimmingCharacters(in: .whitespacesAndNewlines),
          name: name.isEmpty ? nil : name,
          global: global
        )
      )
      items.removeAll { $0.id == item.id }
      items.insert(item, at: 0)
      return true
    } catch {
      errorMessage = text(for: error)
      return false
    }
  }

  func remove(_ item: LiveContentControlItem) async {
    do {
      try await service.remove(kind: kind, url: item.url)
      items.removeAll { $0.id == item.id }
      hiddenVideos?.show(kind, url: item.url)
    } catch {
      errorMessage = text(for: error)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Content controls could not be updated."
  }
}
