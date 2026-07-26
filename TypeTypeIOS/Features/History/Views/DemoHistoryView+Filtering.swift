import SwiftUI

extension DemoHistoryView {
  var filteredEntries: [DemoHistoryEntry] {
    session.historyEntries.filter { entry in
      let matchesSearch =
        searchText.isEmpty
        || entry.video.title.localizedCaseInsensitiveContains(searchText)
        || entry.video.channel.localizedCaseInsensitiveContains(searchText)
      return matchesSearch && includes(entry)
    }
  }

  var displayedEntries: [DemoHistoryEntry] {
    Array(filteredEntries.prefix(visibleCount))
  }

  func includes(_ entry: DemoHistoryEntry) -> Bool {
    switch filter {
    case .all, .week, .month:
      return true
    case .today:
      return entry.group == .today
    case .older:
      guard let selectedDate else { return entry.group != .today }
      return Calendar.current.isDate(
        entryDate(entry),
        inSameDayAs: selectedDate
      )
    }
  }

  func entryDate(_ entry: DemoHistoryEntry) -> Date {
    switch entry.group {
    case .today:
      return Date()
    case .yesterday:
      return Calendar.current.date(
        byAdding: .day,
        value: -1,
        to: Date()
      ) ?? Date()
    case .week:
      return Calendar.current.date(
        byAdding: .day,
        value: -3,
        to: Date()
      ) ?? Date()
    }
  }

  func select(_ video: DemoVideo) {
    selectedVideo = video
  }

  func remove(_ entry: DemoHistoryEntry) {
    withAnimation {
      session.historyEntries.removeAll { $0.id == entry.id }
      session.playbackProgressVideoIDs.remove(entry.video.id)
    }
  }

  func loadMore() {
    guard !isLoadingMore else { return }
    isLoadingMore = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(350))
      visibleCount = min(filteredEntries.count, visibleCount + 6)
      isLoadingMore = false
    }
  }
}
