import Foundation

enum LiveTwitchChatAssetsLoader {
  static func load(
    _ service: LiveTwitchAccountServiceProtocol, login: String
  ) async -> (emotes: [String: LiveTwitchThirdPartyEmote], badges: [String: LiveTwitchChatBadge]) {
    async let global = try? service.chatAssets(login: nil)
    async let channel = try? service.chatAssets(login: login)
    let merged = (await channel ?? .empty).merged(over: await global ?? .empty)
    return (Dictionary(merged.emotes.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first }), merged.badges)
  }
}

@MainActor
final class LiveTwitchVodChatViewModel: ObservableObject {
  static let retryDelay: TimeInterval = 10

  @Published private(set) var window = LiveTwitchVodChatWindow()
  @Published private(set) var unavailable = false
  @Published private(set) var emotes: [String: LiveTwitchThirdPartyEmote] = [:]
  @Published private(set) var badges: [String: LiveTwitchChatBadge] = [:]

  let videoID: String
  private let login: String?
  private let service: LiveTwitchAccountServiceProtocol
  private var loading = false
  private var retryAt: Date?

  init(videoID: String, login: String?, service: LiveTwitchAccountServiceProtocol) {
    self.videoID = videoID
    self.login = login
    self.service = service
  }

  func loadAssets() async {
    guard let login else { return }
    (emotes, badges) = await LiveTwitchChatAssetsLoader.load(service, login: login)
  }

  func follow(position seconds: Double) async {
    guard !loading, !unavailable, retryAt.map({ $0 <= Date() }) ?? true, let request = window.request(at: seconds) else { return }
    loading = true
    defer { loading = false }
    do {
      let page = try await service.videoComments(id: videoID, request: request)
      window.apply(page, for: request, at: seconds)
      retryAt = nil
    } catch is CancellationError {
      return
    } catch {
      if LiveUserError(error) == .contentUnavailable, !window.isLoaded {
        unavailable = true
      } else {
        retryAt = Date().addingTimeInterval(Self.retryDelay)
      }
    }
  }
}
