import Foundation

@MainActor
final class LiveYouTubeSessionViewModel: ObservableObject {
  enum State: Equatable {
    case loading
    case loaded(LiveYouTubeSessionStatus)
    case failed(String)
  }

  @Published private(set) var state = State.loading
  @Published private(set) var browser: LiveYouTubeRemoteBrowser?
  @Published private(set) var isWorking = false
  @Published var errorMessage: String?

  private let service: LiveYouTubeSessionServiceProtocol
  private let instanceURL: () -> URL?
  private let accessToken: () -> String?
  private var browserSessionID: String?

  init(
    service: LiveYouTubeSessionServiceProtocol,
    instanceURL: @escaping () -> URL?,
    accessToken: @escaping () -> String?
  ) {
    self.service = service
    self.instanceURL = instanceURL
    self.accessToken = accessToken
  }

  var isConnected: Bool {
    if case let .loaded(status) = state { return status.isConnected }
    return false
  }

  func refresh() async {
    do {
      state = .loaded(try await service.status())
    } catch {
      state = .failed(Self.text(for: error))
    }
  }

  func connect() async {
    guard browser == nil, !isWorking else { return }
    isWorking = true
    defer { isWorking = false }
    do {
      let session = try await service.startBrowser()
      guard let base = instanceURL(),
        let url = LiveYouTubeSessionService.socketURL(for: session.wsUrl, instance: base)
      else {
        errorMessage = String(localized: "The sign-in browser address does not match this instance.")
        return
      }
      let next = LiveYouTubeRemoteBrowser()
      next.connect(url: url, accessToken: accessToken())
      browserSessionID = session.sessionId
      browser = next
    } catch {
      errorMessage = Self.text(for: error)
    }
  }

  func browserFinished() async {
    browser?.close()
    browser = nil
    browserSessionID = nil
    await refresh()
  }

  func cancel() async {
    browser?.send(.cancel)
    if let browserSessionID {
      do {
        try await service.cancelBrowser(sessionID: browserSessionID)
      } catch {
        AppLogger.app.failure("Cancelling the YouTube sign-in browser", error)
      }
    }
    await browserFinished()
  }

  func disconnect() async {
    isWorking = true
    defer { isWorking = false }
    do {
      try await service.disconnect()
      await refresh()
    } catch {
      errorMessage = Self.text(for: error)
    }
  }

  private static func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription ?? String(localized: "YouTube sign-in is unavailable right now.")
  }
}
