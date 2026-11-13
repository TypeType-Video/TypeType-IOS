import Foundation

@MainActor
final class LiveLinkedAccountsViewModel: ObservableObject {
  @Published private(set) var youtubeConnected: Bool?
  @Published private(set) var youtubeLogin: LiveYouTubeDeviceLogin?
  @Published private(set) var youtubeError: String?
  @Published private(set) var biliBiliState: LiveBiliBiliSessionState?
  @Published private(set) var biliBiliQR: LiveBiliBiliQRLogin?
  @Published private(set) var biliBiliScanned = false
  @Published private(set) var biliBiliError: String?
  @Published private(set) var isBusy = false

  private let youtube: LiveYouTubeSessionServiceProtocol
  private let service: LiveLinkedAccountsServiceProtocol
  private let pause: (Duration) async throws -> Void
  private var youtubeTask: Task<Void, Never>?
  private var biliBiliTask: Task<Void, Never>?

  static let slowDownStep: Duration = .seconds(5)
  static let biliBiliInterval: Duration = .seconds(2)

  init(
    youtube: LiveYouTubeSessionServiceProtocol,
    service: LiveLinkedAccountsServiceProtocol,
    pause: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
  ) {
    self.youtube = youtube
    self.service = service
    self.pause = pause
  }

  func refresh() async {
    async let youtubeStatus = try? youtube.status()
    async let biliBili = try? service.biliBiliState()
    if let status = await youtubeStatus { youtubeConnected = status.isConnected }
    if let state = await biliBili { biliBiliState = state }
  }

  func startYouTube() {
    youtubeTask?.cancel()
    youtubeError = nil
    youtubeLogin = nil
    youtubeTask = Task { [weak self] in await self?.runYouTube() }
  }

  func cancelYouTube() {
    guard youtubeTask != nil else { return }
    youtubeTask?.cancel()
    youtubeTask = nil
    youtubeLogin = nil
    Task { [service] in try? await service.cancelYouTubeLogin() }
  }

  func disconnectYouTube() async {
    await write({ self.youtubeError = $0 }) {
      try await self.youtube.disconnect()
      self.youtubeConnected = false
    }
  }

  func startBiliBili() {
    biliBiliTask?.cancel()
    biliBiliError = nil
    biliBiliQR = nil
    biliBiliScanned = false
    biliBiliTask = Task { [weak self] in await self?.runBiliBili() }
  }

  func cancelBiliBili() {
    biliBiliTask?.cancel()
    biliBiliTask = nil
    biliBiliQR = nil
    biliBiliScanned = false
  }

  func disconnectBiliBili() async {
    await write({ self.biliBiliError = $0 }) {
      try await self.service.disconnectBiliBili()
      self.biliBiliState = .disconnected
    }
  }

  func stop() {
    cancelYouTube()
    cancelBiliBili()
  }

  private func runYouTube() async {
    do {
      let login = try await service.startYouTubeLogin()
      youtubeLogin = login
      var interval = login.interval
      while true {
        try await pause(interval)
        switch try await service.pollYouTubeLogin() {
        case .pending: continue
        case .slowDown: interval += Self.slowDownStep
        case .connected:
          youtubeLogin = nil
          youtubeConnected = true
          youtubeTask = nil
          return
        }
      }
    } catch is CancellationError {
      return
    } catch {
      youtubeLogin = nil
      youtubeTask = nil
      youtubeError = Self.message(for: error)
    }
  }

  private func runBiliBili() async {
    do {
      let qr = try await service.startBiliBiliLogin()
      biliBiliQR = qr
      while true {
        try await pause(Self.biliBiliInterval)
        switch try await service.pollBiliBiliLogin(key: qr.qrcodeKey) {
        case .waiting: continue
        case .scanned: biliBiliScanned = true
        case .confirmed:
          endBiliBili(state: .connected, error: nil)
          return
        case .expired:
          endBiliBili(state: nil, error: String(localized: "The QR code expired. Show a new one."))
          return
        case .failed:
          endBiliBili(state: nil, error: String(localized: "The account could not be linked. Try again."))
          return
        }
      }
    } catch is CancellationError {
      return
    } catch {
      endBiliBili(state: nil, error: Self.message(for: error))
    }
  }

  private func endBiliBili(state: LiveBiliBiliSessionState?, error: String?) {
    biliBiliQR = nil
    biliBiliScanned = false
    biliBiliTask = nil
    if let state { biliBiliState = state }
    biliBiliError = error
  }

  private func write(_ onFailure: @escaping (String) -> Void, _ work: @escaping () async throws -> Void) async {
    guard !isBusy else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      try await work()
    } catch is CancellationError {
      return
    } catch {
      onFailure(Self.message(for: error))
    }
  }

  private static func message(for error: Error) -> String {
    if case let NetworkError.statusCode(_, _, code)? = error as? NetworkError, code == "bilibili_session_unavailable" {
      return String(localized: "BiliBili sign-in is not available on this instance.")
    }
    return (error as? LocalizedError)?.errorDescription ?? String(localized: "The account could not be linked. Try again.")
  }
}
