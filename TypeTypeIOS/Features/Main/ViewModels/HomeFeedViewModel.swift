import Combine
import Foundation

@MainActor
final class HomeFeedViewModel: ObservableObject {
  @Published private(set) var videos: [HomeVideoItem] = []
  @Published private(set) var isLoading: Bool = false
  @Published var errorMessage: String?

  private let service: HomeFeedServiceProtocol

  init(service: HomeFeedServiceProtocol) {
    self.service = service
  }

  func loadIfNeeded(serviceID: Int = 0) async {
    guard videos.isEmpty else { return }
    await reload(serviceID: serviceID)
  }

  func reload(serviceID: Int = 0) async {
    isLoading = true
    errorMessage = nil
    do {
      videos = try await service.trending(serviceID: serviceID)
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
