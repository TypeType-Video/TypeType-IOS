import Foundation

@MainActor
final class LiveDeviceLinkViewModel: ObservableObject {
  enum Outcome: Equatable {
    case approved
    case denied
  }

  @Published var code = ""
  @Published private(set) var request: LiveDeviceLinkRequest?
  @Published private(set) var outcome: Outcome?
  @Published private(set) var isBusy = false
  @Published private(set) var failure: String?

  private let service: LiveDeviceLinkServiceProtocol

  init(service: LiveDeviceLinkServiceProtocol) {
    self.service = service
  }

  var canLookUp: Bool { !LiveDeviceLinkRequest.normalized(code).isEmpty && !isBusy }

  func lookUp() async {
    guard canLookUp else { return }
    let code = code
    await run {
      request = try await service.lookup(code: code)
      outcome = nil
    }
  }

  func approve() async {
    await decide(.approved) { try await self.service.approve(code: $0) }
  }

  func deny() async {
    await decide(.denied) { try await self.service.deny(code: $0) }
  }

  func reset() {
    code = ""
    request = nil
    outcome = nil
    failure = nil
  }

  private func decide(_ result: Outcome, _ call: @escaping (String) async throws -> Void) async {
    guard let request else { return }
    await run {
      try await call(request.userCode)
      self.request = nil
      outcome = result
    }
  }

  private func run(_ work: () async throws -> Void) async {
    guard !isBusy else { return }
    isBusy = true
    failure = nil
    defer { isBusy = false }
    do {
      try await work()
    } catch is CancellationError {
      return
    } catch {
      failure = Self.message(for: error)
    }
  }

  static func message(for error: Error) -> String {
    guard case let NetworkError.statusCode(status, _, _) = error else {
      return String(localized: "The instance could not be reached. Check your connection and try again.")
    }
    switch status {
    case 404: return String(localized: "This code does not exist or has expired. Check the code on the other device.")
    case 409: return String(localized: "This code has already been used.")
    case 429: return String(localized: "Too many attempts. Wait a moment, then try again.")
    case 403: return String(localized: "This instance does not allow signing in other devices with this account.")
    default: return String(localized: "The device could not be signed in. Try again.")
    }
  }
}
