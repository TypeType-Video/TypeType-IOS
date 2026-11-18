import SwiftUI

struct LiveAdminRssView: View {
  static let pageSize = 30

  let service: LiveAdminExtrasServiceProtocol
  @State private var feeds: [LiveAdminRssFeed] = []
  @State private var total = 0
  @State private var page = 0
  @State private var loading = false
  @State private var error: String?

  var body: some View {
    List {
      LiveSection {
        if feeds.isEmpty, !loading { Text("No RSS feed on this instance.").foregroundStyle(.secondary) }
        ForEach(feeds) { item in
          VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: Binding(get: { item.feed.enabled }, set: { value in Task { await setFeed(item, value) } })) {
              VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.feed.name)
                Text(verbatim: item.userName).font(.footnote).foregroundStyle(.secondary)
              }
            }
            Toggle("RSS allowed for this user", isOn: Binding(get: { item.userRssEnabled }, set: { value in Task { await setUser(item, value) } }))
              .font(.footnote)
          }
          .swipeActions {
            Button("Revoke", role: .destructive) { Task { await revoke(item) } }
          }
          .onAppear { if item.id == feeds.last?.id, feeds.count < total { Task { await load(page + 1) } } }
        }
      } footer: {
        if let error { Text(verbatim: error).liveSettingsFooter() }
      }
    }
    .liveGroupedList()
    .navigationTitle("RSS feeds")
    .navigationBarTitleDisplayMode(.inline)
    .task { await load(0) }
  }

  private func load(_ next: Int) async {
    guard !loading else { return }
    loading = true
    defer { loading = false }
    do {
      let answer = try await service.rssFeeds(page: next, limit: Self.pageSize)
      feeds = next == 0 ? answer.items : feeds + answer.items.filter { item in !feeds.contains { $0.id == item.id } }
      total = answer.total
      page = next
    } catch {
      self.error = LiveUserError(error).message ?? String(localized: "The change could not be saved.")
    }
  }

  private func setFeed(_ item: LiveAdminRssFeed, _ enabled: Bool) async {
    await apply { try await service.setRssFeed(id: item.feed.id, enabled: enabled) }
  }

  private func setUser(_ item: LiveAdminRssFeed, _ enabled: Bool) async {
    await apply { try await service.setUserRss(id: item.userId, enabled: enabled) }
  }

  private func revoke(_ item: LiveAdminRssFeed) async {
    await apply { try await service.revokeRssFeed(id: item.feed.id) }
  }

  private func apply(_ action: () async throws -> Void) async {
    do {
      try await action()
      error = nil
    } catch {
      self.error = LiveUserError(error).message ?? String(localized: "The change could not be saved.")
    }
    await load(0)
  }
}
