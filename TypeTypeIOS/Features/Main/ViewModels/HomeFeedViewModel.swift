import Combine
import Foundation

@MainActor
final class HomeFeedViewModel: ObservableObject {
  @Published private(set) var videos: [HomeVideoItem] = []
  @Published private(set) var continueWatching: [ContinueWatchingItem] = []
  @Published private(set) var isLoading: Bool = false
  @Published var errorMessage: String?

  private let homeService: HomeFeedServiceProtocol
  private let libraryService: LibraryServiceProtocol

  init(homeService: HomeFeedServiceProtocol, libraryService: LibraryServiceProtocol) {
    self.homeService = homeService
    self.libraryService = libraryService
  }

  func loadIfNeeded(serviceID: Int = 0) async {
    guard videos.isEmpty else { return }
    await reload(serviceID: serviceID)
  }

  func reload(serviceID: Int = 0) async {
    isLoading = true
    errorMessage = nil
    do {
      videos = try await homeService.trending(serviceID: serviceID)
      do {
        let historyItems = try await libraryService.history(limit: 40, offset: 0)
        continueWatching = historyItems
          .filter { $0.duration > 0 && $0.progress > 0 && $0.progress < $0.duration }
          .prefix(12)
          .map(ContinueWatchingItem.init)
      } catch {
        continueWatching = []
      }
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load feed."
      isLoading = false
    } catch {
      errorMessage = "Unable to load feed."
      isLoading = false
    }
  }
}
