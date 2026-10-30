import SwiftUI

struct DemoHistoryView: View {
  @Environment(\.themePalette) private var palette
  @EnvironmentObject var session: DemoSessionStore
  @State var searchText = ""
  @State var filter = DemoHistoryFilterBar.Filter.all
  @State var selectedDate: Date?
  @State var selectedVideo: DemoVideo?
  @State var confirmsClear = false
  @State var visibleCount = 6
  @State var isLoadingMore = false

  private let columns = [
    GridItem(.adaptive(minimum: 330, maximum: 520), spacing: 14),
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 24) {
          DemoHistoryFilterBar(
            selection: $filter,
            selectedDate: $selectedDate,
            resultCount: filteredEntries.count
          )
          historyContent
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 30)
      }
      .defaultScrollAnchor(.top)
      .background(palette.background)
      .navigationTitle("History")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, prompt: "Search history")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Clear", role: .destructive) {
            confirmsClear = true
          }
          .disabled(session.historyEntries.isEmpty)
        }
      }
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(
        palette.background.opacity(0.96),
        for: .navigationBar
      )
      .navigationDestination(item: $selectedVideo) { video in
        DemoWatchView(video: video)
      }
      .onChange(of: searchText) { visibleCount = 6 }
      .onChange(of: filter) { visibleCount = 6 }
      .onChange(of: selectedDate) { visibleCount = 6 }
      .confirmationDialog(
        "Clear watch history?",
        isPresented: $confirmsClear,
        titleVisibility: .visible
      ) {
        Button("Clear all", role: .destructive) {
          withAnimation {
            session.clearHistory()
          }
        }
      } message: {
        Text("This removes every video from this local mock history.")
      }
    }
    .accessibilityIdentifier("demo.history.screen")
  }

  @ViewBuilder
  private var historyContent: some View {
    if filteredEntries.isEmpty {
      ContentUnavailableView.search(text: searchText)
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    } else {
      ForEach(DemoHistoryEntry.Group.allCases, id: \.self) { group in
        let groupEntries = displayedEntries.filter { $0.group == group }
        if !groupEntries.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            DemoSectionLabel(title: group.rawValue)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
              ForEach(groupEntries) { entry in
                DemoHistoryRow(
                  entry: entry,
                  onSelect: { select(entry.video) },
                  onRemove: { remove(entry) }
                )
              }
            }
          }
        }
      }
      LiveIncrementalLoadingTrigger(
        canLoadMore: visibleCount < filteredEntries.count,
        isLoading: isLoadingMore,
        label: "Loading more history",
        identifier: "demo.history.loading",
        action: loadMore
      )
    }
  }
}
