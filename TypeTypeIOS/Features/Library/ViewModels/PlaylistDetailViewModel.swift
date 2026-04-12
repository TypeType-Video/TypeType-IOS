import Combine
import Foundation

@MainActor
final class PlaylistDetailViewModel: ObservableObject {
  @Published private(set) var playlist: PlaylistSummary?
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isMutating: Bool = false
  @Published var editedName: String = ""
  @Published var editedDescription: String = ""
  @Published var infoMessage: String?
  @Published var errorMessage: String?

  private let playlistID: String
  private let service: LibraryServiceProtocol
  var currentPlaylistID: String? { playlist?.id }

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
      editedName = playlist?.name ?? ""
      editedDescription = playlist?.description ?? ""
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load playlist."
      isLoading = false
    } catch {
      errorMessage = "Unable to load playlist."
      isLoading = false
    }
  }

  func saveDetails() async {
    guard !isMutating else { return }
    guard let playlist else { return }
    let name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else {
      errorMessage = "Playlist name cannot be empty."
      return
    }
    isMutating = true
    infoMessage = nil
    errorMessage = nil
    do {
      try await service.updatePlaylist(id: playlist.id, name: name, description: editedDescription)
      self.playlist = PlaylistSummary(
        id: playlist.id,
        name: name,
        description: editedDescription,
        videos: playlist.videos,
        createdAt: playlist.createdAt
      )
      infoMessage = "Playlist updated"
      isMutating = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to update playlist."
      isMutating = false
    } catch {
      errorMessage = "Unable to update playlist."
      isMutating = false
    }
  }

  func deletePlaylist() async {
    guard !isMutating else { return }
    guard let playlist else { return }
    isMutating = true
    infoMessage = nil
    errorMessage = nil
    do {
      try await service.deletePlaylist(id: playlist.id)
      self.playlist = nil
      infoMessage = "Playlist deleted"
      isMutating = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to delete playlist."
      isMutating = false
    } catch {
      errorMessage = "Unable to delete playlist."
      isMutating = false
    }
  }

  func remove(video: PlaylistVideoEntry) async {
    guard !isMutating else { return }
    guard let playlist else { return }
    isMutating = true
    infoMessage = nil
    errorMessage = nil
    do {
      try await service.removeVideo(from: playlist.id, videoURL: video.url)
      self.playlist = PlaylistSummary(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        videos: playlist.videos.filter { $0.url != video.url },
        createdAt: playlist.createdAt
      )
      infoMessage = "Video removed"
      isMutating = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to remove video."
      isMutating = false
    } catch {
      errorMessage = "Unable to remove video."
      isMutating = false
    }
  }
}
