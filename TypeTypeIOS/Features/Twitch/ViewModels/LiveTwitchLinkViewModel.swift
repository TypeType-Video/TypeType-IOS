import Foundation

@MainActor
final class LiveTwitchLinkViewModel: ObservableObject {
  static let slowDownStep: Duration = .seconds(5)

  @Published private(set) var status: LiveTwitchAccountStatus?
  @Published private(set) var device: LiveTwitchDeviceCode?
  @Published private(set) var error: String?
  @Published private(set) var isBusy = false

  private let service: LiveTwitchAccountServiceProtocol
  private let pause: (Duration) async throws -> Void
  private var task: Task<Void, Never>?

  init(service: LiveTwitchAccountServiceProtocol, pause: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
    self.service = service
    self.pause = pause
  }

  var isLinked: Bool { status?.linked == true }

  func refresh() async {
    do {
      status = try await service.account()
    } catch {
      self.error = LiveUserError(error).message ?? String(localized: "Twitch could not be loaded right now.")
    }
  }

  func start() {
    task?.cancel()
    error = nil
    task = Task { [weak self] in await self?.run() }
  }

  func cancel() {
    task?.cancel()
    task = nil
    device = nil
  }

  func unlink() async {
    isBusy = true
    defer { isBusy = false }
    do {
      try await service.unlink()
      status = LiveTwitchAccountStatus(linked: false, login: nil, displayName: nil, avatarURL: nil)
    } catch {
      self.error = LiveUserError(error).message ?? String(localized: "Twitch could not be loaded right now.")
    }
  }

  private func run() async {
    do {
      let code = try await service.startLink()
      device = code
      var interval: Duration = .seconds(max(code.interval, 1))
      let deadline = Date().addingTimeInterval(TimeInterval(code.expiresIn))
      while Date() < deadline {
        try await pause(interval)
        let answer = try await service.pollLink(deviceCode: code.deviceCode)
        switch answer.status {
        case .pending: continue
        case .slowDown: interval += Self.slowDownStep
        case .ok:
          status = answer.account ?? LiveTwitchAccountStatus(linked: true, login: nil, displayName: nil, avatarURL: nil)
          device = nil
          task = nil
          return
        }
      }
      device = nil
      error = String(localized: "The code expired. Start again.")
    } catch is CancellationError {
      return
    } catch {
      device = nil
      self.error = LiveUserError(error).message ?? String(localized: "Twitch could not be loaded right now.")
    }
    task = nil
  }
}
