import SwiftUI

struct DemoPrivacyView: View {
  enum ClearAction: String, Identifiable {
    case history = "Watch history"
    case search = "Search history"
    case subscriptions = "Subscriptions"

    var id: String { rawValue }
  }

  @EnvironmentObject private var session: DemoSessionStore
  @State private var pendingClear: ClearAction?

  var body: some View {
    Form {
      Section {
        Toggle("Watch history tracking", isOn: tracksHistory)
      } header: { Text("Privacy").liveSectionHeader() }

      Section {
        dataRow("Watch history", count: session.historyEntries.count, id: "history") {
          pendingClear = .history
        }
        dataRow("Search history", count: session.recentSearches.count, id: "search") {
          pendingClear = .search
        }
        dataRow("Subscriptions", count: session.followedChannelIDs.count, id: "subscriptions") {
          pendingClear = .subscriptions
        }
      } header: { Text("Stored data").liveSectionHeader() }

      blockedContent

      Section {
        Text("Every counter and clear action is local mock data.")
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("Privacy")
    .navigationBarTitleDisplayMode(.inline)
    .confirmationDialog(
      confirmationTitle,
      isPresented: confirmsClear,
      titleVisibility: .visible
    ) {
      Button(confirmButtonTitle, role: .destructive) {
        performClear()
      }
      Button("Cancel", role: .cancel) {
        pendingClear = nil
      }
    } message: {
      Text("This action changes the shared local mock session.")
    }
    .accessibilityIdentifier("demo.privacy.screen")
  }

  @ViewBuilder
  private var blockedContent: some View {
    Section {
      if session.blockedChannelNames.isEmpty && session.blockedVideoIDs.isEmpty {
        Text("No blocked channels or videos.")
          .foregroundStyle(.secondary)
      } else {
        ForEach(session.blockedChannelNames.sorted(), id: \.self) { channel in
          unblockRow(channel, detail: "Channel") {
            session.blockedChannelNames.remove(channel)
          }
        }
        ForEach(session.blockedVideoIDs.sorted(), id: \.self) { videoID in
          unblockRow(videoTitle(videoID), detail: "Video") {
            session.blockedVideoIDs.remove(videoID)
          }
        }
      }
    } header: { Text("Blocked content").liveSectionHeader() }
  }

  private func dataRow(
    _ title: String,
    count: Int,
    id: String,
    clear: @escaping () -> Void
  ) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        Text("\(count) entries")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button("Clear", role: .destructive, action: clear)
        .disabled(count == 0)
        .accessibilityIdentifier("demo.privacy.clear.\(id)")
    }
  }

  private func unblockRow(
    _ title: String,
    detail: String,
    action: @escaping () -> Void
  ) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        Text(detail).font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
      Button("Unblock", action: action)
    }
  }

  private var tracksHistory: Binding<Bool> {
    Binding(
      get: { session.preferences.tracksHistory },
      set: { session.setPreference(\.tracksHistory, to: $0) }
    )
  }

  private func videoTitle(_ videoID: String) -> String {
    DemoSearchCatalog.videos.first { $0.id == videoID }?.title ?? videoID
  }

  private var confirmsClear: Binding<Bool> {
    Binding(
      get: { pendingClear != nil },
      set: { if !$0 { pendingClear = nil } }
    )
  }

  private var confirmationTitle: String {
    guard let pendingClear else { return "Clear stored data?" }
    return pendingClear == .subscriptions
      ? "Unsubscribe from every channel?"
      : "Clear \(pendingClear.rawValue.lowercased())?"
  }

  private var confirmButtonTitle: String {
    pendingClear == .subscriptions ? "Unsubscribe all" : "Clear"
  }

  private func performClear() {
    switch pendingClear {
    case .history:
      session.clearHistory()
    case .search:
      session.recentSearches.removeAll()
    case .subscriptions:
      session.followedChannelIDs.removeAll()
    case nil:
      break
    }
    pendingClear = nil
  }
}
