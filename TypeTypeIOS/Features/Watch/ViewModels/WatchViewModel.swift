import Combine
import Foundation

@MainActor
final class WatchViewModel: ObservableObject {
  @Published private(set) var stream: WatchStream?
  @Published private(set) var isLoading: Bool = false
  @Published var errorMessage: String?

  private let videoURL: String
  private let watchService: WatchServiceProtocol

  init(videoURL: String, watchService: WatchServiceProtocol) {
    self.videoURL = videoURL
    self.watchService = watchService
  }

  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    do {
      stream = try await watchService.stream(for: videoURL)
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load stream."
      isLoading = false
    } catch {
      errorMessage = "Unable to load stream."
      isLoading = false
    }
  }
}
