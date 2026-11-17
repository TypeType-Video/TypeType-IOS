import Foundation

@MainActor
final class LiveTwitchChannelViewModel: ObservableObject {
  enum State {
    case loading
    case loaded(LiveTwitchChannel)
    case notFound
    case failed(String)
  }

  @Published private(set) var state = State.loading
  private let login: String
  private let service: LiveTwitchServiceProtocol
  private var generation = 0

  init(login: String, service: LiveTwitchServiceProtocol) {
    self.login = login
    self.service = service
  }

  var title: String? {
    guard case let .loaded(channel) = state else { return nil }
    return channel.user.name
  }

  func load() async {
    generation += 1
    let current = generation
    if case .loaded = state {} else { state = .loading }
    do {
      let channel = try await service.channel(login: login)
      guard current == generation else { return }
      state = .loaded(channel)
    } catch is CancellationError {
      return
    } catch {
      guard current == generation else { return }
      state = LiveUserError(error) == .contentUnavailable ? .notFound : .failed(LiveTwitchFailure.message(for: error))
    }
  }
}
