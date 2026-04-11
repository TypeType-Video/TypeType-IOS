import Combine
import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
  enum Mode: String, CaseIterable, Identifiable {
    case history
    case playlists

    var id: String { rawValue }
  }

  @Published var mode: Mode = .history
  @Published private(set) var history: [HistoryEntry] = []
  @Published private(set) var playlists: [PlaylistSummary] = []
  @Published private(set) var isLoadingHistory: Bool = false
  @Published private(set) var isLoadingPlaylists: Bool = false
  @Published var errorMessage: String?

  private let service: LibraryServiceProtocol

  init(service: LibraryServiceProtocol) {
    self.service = service
  }

  func loadIfNeeded() async {
    if history.isEmpty { await loadHistory() }
    if playlists.isEmpty { await loadPlaylists() }
  }

  func refreshCurrent() async {
    switch mode {
    case .history:
      await loadHistory()
    case .playlists:
      await loadPlaylists()
    }
  }

  func loadHistory() async {
    isLoadingHistory = true
    errorMessage = nil
    do {
      history = try await service.history(limit: 80, offset: 0)
      isLoadingHistory = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load history."
      isLoadingHistory = false
    } catch {
      errorMessage = "Unable to load history."
      isLoadingHistory = false
    }
  }

  func loadPlaylists() async {
    isLoadingPlaylists = true
    errorMessage = nil
    do {
      playlists = try await service.playlists()
      isLoadingPlaylists = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load playlists."
      isLoadingPlaylists = false
    } catch {
      errorMessage = "Unable to load playlists."
      isLoadingPlaylists = false
    }
  }
}
