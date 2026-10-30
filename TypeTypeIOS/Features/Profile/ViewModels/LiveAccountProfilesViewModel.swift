import Foundation

@MainActor
final class LiveAccountProfilesViewModel: ObservableObject {
  @Published private(set) var profiles: AccountProfilesResponse?
  @Published private(set) var isBusy = false
  @Published var newName = ""
  @Published var errorMessage: String?
  @Published private(set) var isUnavailable = false

  private let service: LiveAccountProfileServiceProtocol

  init(service: LiveAccountProfileServiceProtocol) {
    self.service = service
  }

  // 404 on servers without the profiles route, 403 where an instance turns them off: neither is a failure.
  func load() async {
    await perform {
      do {
        self.profiles = try await self.service.list()
        self.isUnavailable = false
      } catch NetworkError.statusCode(let status, _) where status == 403 || status == 404 {
        self.isUnavailable = true
      }
    }
  }

  func create() async {
    let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return }
    await perform {
      _ = try await self.service.create(name: name)
      self.newName = ""
      self.profiles = try await self.service.list()
    }
  }

  func rename(_ profile: AccountProfileItem, to name: String) async {
    await perform {
      _ = try await self.service.rename(id: profile.id, name: name)
      self.profiles = try await self.service.list()
    }
  }

  func setDefault(_ profile: AccountProfileItem) async {
    await perform {
      _ = try await self.service.setDefault(id: profile.id)
      self.profiles = try await self.service.list()
    }
  }

  func delete(_ profile: AccountProfileItem) async {
    await perform {
      try await self.service.delete(id: profile.id)
      self.profiles = try await self.service.list()
    }
  }

  private func perform(_ operation: @escaping () async throws -> Void) async {
    guard !isBusy else { return }
    isBusy = true
    errorMessage = nil
    do {
      try await operation()
    } catch {
      errorMessage = error.localizedDescription
    }
    isBusy = false
  }
}
