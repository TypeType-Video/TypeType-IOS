import SwiftUI

struct DemoSearchView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var session: DemoSessionStore
  @State var query: String
  @State var selectedScope: DemoSearchScope = .all
  @State var selectedService: DemoSearchService = .youtube
  @State var contentFilter: DemoSearchContentFilter = .all
  @State var sortOrder: DemoSearchSort = .relevance
  @State var visibleVideoCount = 4
  @State var isLoadingMore = false
  @State var resultState = DemoSearchResultState.normal
  @State var selectedVideo: DemoVideo?
  @State var selectedChannel: DemoSearchChannel?
  @State var selectedPlaylist: DemoPlaylist?

  init(initialQuery: String = "") {
    _query = State(initialValue: initialQuery)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 24) {
          if normalizedQuery.isEmpty {
            discovery
          } else {
            results
          }
        }
        .padding(.vertical, 16)
      }
      .background(DemoTheme.background)
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(
        DemoTheme.background.opacity(0.96),
        for: .navigationBar
      )
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close", systemImage: "xmark") {
            dismiss()
          }
        }
      }
      .searchable(
        text: $query,
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: "Search videos, channels..."
      )
      .onSubmit(of: .search, rememberQuery)
      .onAppear {
        selectedService =
          DemoSearchService(rawValue: session.preferences.defaultService)
          ?? .youtube
      }
      .onChange(of: query) {
        resultState = .normal
        resetPagination()
      }
      .onChange(of: selectedService) {
        contentFilter = .all
        resetPagination()
      }
      .onChange(of: contentFilter) {
        resetPagination()
      }
      .onChange(of: sortOrder) {
        resetPagination()
      }
      .navigationDestination(item: $selectedVideo) { video in
        DemoWatchView(video: video)
      }
      .navigationDestination(item: $selectedChannel) { channel in
        DemoSearchChannelDetailView(channel: channel)
      }
      .navigationDestination(item: $selectedPlaylist) { playlist in
        DemoSearchPlaylistDetailView(playlist: playlist)
      }
    }
    .preferredColorScheme(session.preferences.colorScheme)
    .tint(session.preferences.accentColor)
    .accessibilityIdentifier("demo.search.screen")
  }
}
