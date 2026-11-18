import Foundation

@MainActor
final class LiveServerStatusMonitor: ObservableObject {
  static let lossGrace: Duration = .seconds(3)
  static let backVisible: Duration = .seconds(3)

  @Published private(set) var status = LiveServerStatus()
  @Published private(set) var showsBack = false

  private let service: LiveServerEventsService
  private let pause: (Duration) async throws -> Void
  private var grace: Task<Void, Never>?
  private var back: Task<Void, Never>?

  init(service: LiveServerEventsService, pause: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
    self.service = service
    self.pause = pause
  }

  var message: String? {
    switch status.phase {
    case .unreachable: return String(localized: "Connection to the server lost. Reconnecting.")
    case .restarting: return String(localized: "The server is restarting. Everything resumes by itself.")
    case .online: break
    }
    let base: String? = switch status.notice?.kind {
    case .update: String(localized: "A server update is coming. Playback will resume by itself.")
    case .maintenance: String(localized: "Server maintenance in progress.")
    default: nil
    }
    if let base { return [base, status.notice?.trimmedMessage].compactMap { $0 }.joined(separator: " ") }
    return showsBack ? String(localized: "The server is back.") : nil
  }

  var isWaiting: Bool { status.phase != .online }

  func run() async {
    for await event in service.events() {
      apply(event)
    }
    grace?.cancel()
  }

  func apply(_ event: LiveServerEvent) {
    switch event {
    case let .hello(hello): resume { $0.greeted(hello) }
    case .reachable: resume { $0.reached() }
    case let .notice(notice): status.announced(notice)
    case .cleared: status.cleared()
    case .lost:
      status.lost()
      guard grace == nil else { return }
      grace = Task { [weak self, pause] in
        guard (try? await pause(Self.lossGrace)) != nil, let self else { return }
        self.grace = nil
        self.status.lossConfirmed()
      }
    }
  }

  private func resume(_ change: (inout LiveServerStatus) -> Void) {
    grace?.cancel()
    grace = nil
    let before = status.resumes
    change(&status)
    guard status.resumes != before else { return }
    showsBack = true
    back?.cancel()
    back = Task { [weak self, pause] in
      guard (try? await pause(Self.backVisible)) != nil else { return }
      self?.showsBack = false
    }
  }
}
