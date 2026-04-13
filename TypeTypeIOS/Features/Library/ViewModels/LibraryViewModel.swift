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
  @Published private(set) var isMutatingPlaylists: Bool = false
  @Published private(set) var isMutatingHistory: Bool = false
  @Published var historyQuery: String = ""
  @Published var historyFromDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
  @Published var historyToDate: Date = .now
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
      let query = historyQuery.trimmingCharacters(in: .whitespacesAndNewlines)
      let start = min(historyFromDate, historyToDate)
      let end = max(historyFromDate, historyToDate)
      let from = Int64(start.timeIntervalSince1970 * 1_000)
      let to = Int64(end.timeIntervalSince1970 * 1_000)
      history = try await service.history(
        query: query.isEmpty ? nil : query,
        from: from,
        to: to,
        limit: 80,
        offset: 0
      )
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

  func createPlaylist(name: String, description: String) async {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    guard !isMutatingPlaylists else { return }
    isMutatingPlaylists = true
    errorMessage = nil
    do {
      let created = try await service.createPlaylist(name: trimmed, description: description)
      playlists.insert(created, at: 0)
      isMutatingPlaylists = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to create playlist."
      isMutatingPlaylists = false
    } catch {
      errorMessage = "Unable to create playlist."
      isMutatingPlaylists = false
    }
  }

  func deletePlaylist(_ playlist: PlaylistSummary) async {
    guard !isMutatingPlaylists else { return }
    isMutatingPlaylists = true
    errorMessage = nil
    do {
      try await service.deletePlaylist(id: playlist.id)
      playlists.removeAll(where: { $0.id == playlist.id })
      isMutatingPlaylists = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to delete playlist."
      isMutatingPlaylists = false
    } catch {
      errorMessage = "Unable to delete playlist."
      isMutatingPlaylists = false
    }
  }

  func deleteHistoryEntry(_ item: HistoryEntry) async {
    guard !isMutatingHistory else { return }
    isMutatingHistory = true
    errorMessage = nil
    do {
      try await service.deleteHistoryEntry(id: item.id)
      history.removeAll(where: { $0.id == item.id })
      isMutatingHistory = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to remove history item."
      isMutatingHistory = false
    } catch {
      errorMessage = "Unable to remove history item."
      isMutatingHistory = false
    }
  }

  func clearHistory() async {
    guard !isMutatingHistory else { return }
    isMutatingHistory = true
    errorMessage = nil
    do {
      try await service.clearHistory()
      history = []
      isMutatingHistory = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to clear history."
      isMutatingHistory = false
    } catch {
      errorMessage = "Unable to clear history."
      isMutatingHistory = false
    }
  }

  func unsubscribeAllChannels(using service: SubscriptionsServiceProtocol) async {
    guard !isMutatingHistory else { return }
    isMutatingHistory = true
    errorMessage = nil
    do {
      let channels = try await service.channels()
      for channel in channels {
        try await service.setSubscription(
          channelURL: channel.channelUrl,
          name: channel.name,
          avatarURL: channel.avatarUrl,
          enabled: false
        )
      }
      isMutatingHistory = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to unsubscribe all channels."
      isMutatingHistory = false
    } catch {
      errorMessage = "Unable to unsubscribe all channels."
      isMutatingHistory = false
    }
  }
}
