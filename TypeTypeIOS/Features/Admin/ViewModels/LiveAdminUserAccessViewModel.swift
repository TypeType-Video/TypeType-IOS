import Foundation

@MainActor
final class LiveAdminUserAccessViewModel: ObservableObject {
  enum State: Equatable {
    case idle, loading, loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var list: LiveAdminUserAllowList?
  @Published private(set) var isBusy = false

  let userID: String
  private let service: LiveAdminAccessServiceProtocol

  init(userID: String, service: LiveAdminAccessServiceProtocol) {
    self.userID = userID
    self.service = service
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      list = try await service.userAllowList(id: userID)
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func setRestricted(_ restricted: Bool) async {
    _ = await mutate {
      try await service.updateAccessMode(
        id: userID,
        mode: restricted ? "allow_list" : "unrestricted"
      )
    }
  }

  func addChannel(url: String, name: String) async -> Bool {
    await mutate {
      try await service.addChannel(
        userID: userID,
        item: LiveContentControlItem(
          url: url,
          name: name.isEmpty ? nil : name
        )
      )
    }
  }

  func addPlaylist(url: String, title: String) async -> Bool {
    await mutate {
      try await service.addPlaylist(
        userID: userID,
        item: LiveAllowedPlaylistItem(
          url: url,
          title: title.isEmpty ? nil : title
        )
      )
    }
  }

  func removeChannel(_ item: LiveContentControlItem) async {
    _ = await mutate {
      try await service.removeChannel(userID: userID, url: item.url)
    }
  }

  func removePlaylist(_ item: LiveAllowedPlaylistItem) async {
    _ = await mutate {
      try await service.removePlaylist(userID: userID, url: item.url)
    }
  }

  private func mutate(
    _ operation: () async throws -> Void
  ) async -> Bool {
    guard !isBusy else { return false }
    isBusy = true
    defer { isBusy = false }
    do {
      try await operation()
      await reload()
      return true
    } catch {
      state = .failed(text(for: error))
      return false
    }
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "This user's access could not be updated."
  }
}
