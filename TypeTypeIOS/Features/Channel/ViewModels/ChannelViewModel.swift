import Foundation

@MainActor
final class ChannelViewModel: ObservableObject {
  @Published private(set) var page: ChannelPage?
  @Published private(set) var videos: [HomeVideoItem] = []
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isLoadingMore: Bool = false
  @Published private(set) var canLoadMore: Bool = true
  @Published var errorMessage: String?

  private let url: String
  private let service: ChannelServiceProtocol
  private var nextPage: String?

  init(url: String, service: ChannelServiceProtocol) {
    self.url = url
    self.service = service
  }

  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    do {
      let result = try await service.channel(url: url, nextPage: nil)
      page = result
      videos = result.videos
      nextPage = result.nextPage
      canLoadMore = result.nextPage != nil
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load channel."
      isLoading = false
    } catch {
      errorMessage = "Unable to load channel."
      isLoading = false
    }
  }

  func loadMore() async {
    guard !isLoadingMore else { return }
    guard canLoadMore else { return }
    guard let nextPage else { return }
    isLoadingMore = true
    do {
      let result = try await service.channel(url: url, nextPage: nextPage)
      videos += result.videos
      self.nextPage = result.nextPage
      canLoadMore = result.nextPage != nil
      isLoadingMore = false
    } catch {
      isLoadingMore = false
    }
  }
}
