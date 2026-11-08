import Foundation

@MainActor
final class LiveSeekbarIconViewModel: ObservableObject {
  enum Failure: Equatable {
    case unsupported
    case tooLarge
    case failed
  }

  @Published private(set) var isBusy = false
  @Published private(set) var failure: Failure?

  private let service: LiveProfileServiceProtocol
  private let settings: LiveSettingsViewModel

  init(service: LiveProfileServiceProtocol, settings: LiveSettingsViewModel) {
    self.service = service
    self.settings = settings
  }

  func upload(_ data: Data?) async {
    guard !isBusy else { return }
    guard let data else {
      failure = .unsupported
      return
    }
    isBusy = true
    let payload = await Task.detached(priority: .userInitiated) { LiveSeekbarIconPayload.make(from: data) }.value
    isBusy = false
    switch payload {
    case .unsupported: failure = .unsupported
    case .tooLarge: failure = .tooLarge
    case let .ready(bytes, mediaType):
      await run { [service] in try await service.uploadSeekbarIcon(data: bytes, mediaType: mediaType) }
    }
  }

  func remove() async {
    await run { [service] in try await service.clearSeekbarIcon() }
  }

  private func run(_ work: () async throws -> Void) async {
    guard !isBusy else { return }
    isBusy = true
    failure = nil
    defer { isBusy = false }
    do {
      try await work()
      try await settings.adoptServerSettings()
    } catch NetworkError.statusCode(413, _) {
      failure = .tooLarge
    } catch NetworkError.statusCode(415, _) {
      failure = .unsupported
    } catch {
      AppLogger.app.failure("Changing the seekbar icon", error)
      failure = .failed
    }
  }
}
