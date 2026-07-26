import Foundation

@MainActor
final class LiveAdminSessionsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var sessions: [LiveAdminSession] = []

  private let service: LiveAdminServiceProtocol

  init(service: LiveAdminServiceProtocol) {
    self.service = service
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      sessions = try await service.sessions().sorted {
        $0.lastActivityAt > $1.lastActivityAt
      }
      state = .loaded
    } catch {
      let message = (error as? LocalizedError)?.errorDescription
        ?? "Active sessions could not be loaded."
      state = .failed(message)
    }
  }
}
