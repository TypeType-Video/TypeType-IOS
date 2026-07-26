import Foundation

@MainActor
final class LiveYouTubeSessionViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var status: LiveYouTubeSessionStatus?
  @Published private(set) var browserSession:
    LiveYouTubeRemoteBrowserSession?
  @Published private(set) var isBusy = false
  @Published private(set) var message: String?

  private let service: LiveYouTubeSessionServiceProtocol

  init(service: LiveYouTubeSessionServiceProtocol) {
    self.service = service
  }

  func prepare() async {
    guard state == .idle else { return }
    await refresh()
  }

  func refresh() async {
    state = .loading
    do {
      status = try await service.status()
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func start(baseURL: URL?) async -> URL? {
    guard !isBusy else { return nil }
    isBusy = true
    defer { isBusy = false }
    do {
      let session = try await service.startRemoteBrowser(
        returnTo: nil
      )
      browserSession = session
      state = .loaded
      return resolvedURL(session.webSocketURL, baseURL: baseURL)
    } catch {
      state = .failed(text(for: error))
      return nil
    }
  }

  func cancelBrowser() async {
    guard let browserSession else { return }
    try? await service.cancelRemoteBrowser(
      sessionID: browserSession.sessionID
    )
    self.browserSession = nil
  }

  func completeBrowser() async {
    browserSession = nil
    message = "YouTube session connected."
    await refresh()
  }

  func disconnect() async {
    guard !isBusy else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      try await service.disconnect()
      message = "YouTube session disconnected."
      await refresh()
    } catch {
      state = .failed(text(for: error))
    }
  }

  private func resolvedURL(
    _ rawValue: String,
    baseURL: URL?
  ) -> URL? {
    if let absolute = URL(string: rawValue),
      let scheme = absolute.scheme,
      ["ws", "wss"].contains(scheme) {
      return absolute
    }
    guard let baseURL,
      var components = URLComponents(
        url: baseURL,
        resolvingAgainstBaseURL: false
      )
    else {
      return nil
    }
    if let absolute = URL(string: rawValue),
      let scheme = absolute.scheme,
      ["http", "https"].contains(scheme) {
      components = URLComponents(
        url: absolute,
        resolvingAgainstBaseURL: false
      ) ?? components
    } else {
      let basePath = components.path.hasSuffix("/")
        ? String(components.path.dropLast())
        : components.path
      let parts = rawValue.split(
        separator: "?",
        maxSplits: 1,
        omittingEmptySubsequences: false
      )
      components.path = basePath + "/" + parts[0]
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      components.percentEncodedQuery = parts.count > 1
        ? String(parts[1])
        : nil
    }
    components.scheme = components.scheme == "https" ? "wss" : "ws"
    return components.url
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "YouTube session is unavailable."
  }
}
