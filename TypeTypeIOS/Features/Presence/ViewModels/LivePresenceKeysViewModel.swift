import Foundation

@MainActor
final class LivePresenceKeysViewModel: ObservableObject {
  static let nameLimit = 50

  @Published private(set) var keys: [LivePresenceKey] = []
  @Published private(set) var loaded = false
  @Published private(set) var createdToken: String?
  @Published private(set) var isBusy = false
  @Published private(set) var error: String?
  @Published var name = ""

  private let service: LivePresenceServiceProtocol
  private var createdKeyID: String?

  init(service: LivePresenceServiceProtocol) {
    self.service = service
  }

  var canCreate: Bool { !trimmedName.isEmpty && !isBusy }
  private var trimmedName: String { String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.nameLimit)) }

  func load() async {
    do {
      keys = try await service.keys()
      error = nil
    } catch {
      self.error = String(localized: "Unable to load presence keys")
    }
    loaded = true
  }

  func create() async {
    guard canCreate else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      let created = try await service.create(name: trimmedName)
      keys.append(created.key)
      createdToken = created.token
      createdKeyID = created.key.id
      name = ""
      error = nil
    } catch {
      self.error = String(localized: "Unable to create presence key")
    }
  }

  func revoke(_ key: LivePresenceKey) async {
    do {
      try await service.revoke(id: key.id)
      keys.removeAll { $0.id == key.id }
      if key.id == createdKeyID {
        createdToken = nil
        createdKeyID = nil
      }
    } catch {
      self.error = String(localized: "Unable to revoke presence key")
    }
  }
}
