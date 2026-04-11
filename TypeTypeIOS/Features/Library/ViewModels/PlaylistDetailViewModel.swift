import Combine
import Foundation

@MainActor
final class PlaylistDetailViewModel: ObservableObject {
  @Published private(set) var playlist: PlaylistSummary?
  @Published private(set) var isLoading: Bool = false
  @Published var errorMessage: String?

  private let playlistID: String
  private let service: LibraryServiceProtocol

  init(playlistID: String, service: LibraryServiceProtocol) {
    self.playlistID = playlistID
    self.service = service
  }

  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    do {
      playlist = try await service.playlist(id: playlistID)
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load playlist."
      isLoading = false
    } catch {
      errorMessage = "Unable to load playlist."
      isLoading = false
    }
  }
}
