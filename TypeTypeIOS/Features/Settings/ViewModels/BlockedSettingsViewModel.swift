import Foundation

@MainActor
final class BlockedSettingsViewModel: ObservableObject {
  @Published private(set) var blockedChannels: [BlockedItem] = []
  @Published private(set) var blockedVideos: [BlockedItem] = []
  @Published private(set) var isLoading: Bool = false
  @Published var errorMessage: String?

  private let service: BlockedServiceProtocol

  init(service: BlockedServiceProtocol) {
    self.service = service
  }

  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    do {
      async let channelsReq = service.channels()
      async let videosReq = service.videos()
      blockedChannels = try await channelsReq
      blockedVideos = try await videosReq
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load blocked items."
      isLoading = false
    } catch {
      errorMessage = "Unable to load blocked items."
      isLoading = false
    }
  }

  func unblockChannel(_ item: BlockedItem) async {
    do {
      try await service.removeChannel(url: item.url)
      blockedChannels.removeAll(where: { $0.url == item.url })
    } catch {
      errorMessage = "Unable to unblock channel."
    }
  }

  func unblockVideo(_ item: BlockedItem) async {
    do {
      try await service.removeVideo(url: item.url)
      blockedVideos.removeAll(where: { $0.url == item.url })
    } catch {
      errorMessage = "Unable to unblock video."
    }
  }
}
