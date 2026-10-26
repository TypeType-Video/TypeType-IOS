import SwiftUI

struct LiveSearchHistoryView: View {
  @ObservedObject var viewModel: LiveSearchViewModel
  let dependencies: AppDependencies
  let onVideo: (LiveVideoItem) -> Void
  let onChannel: (String) -> Void
  @State private var confirmsClear = false

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        if !viewModel.history.isEmpty {
          historySection
        }
        trendingSection
      }
      .padding(16)
    }
    .background(DemoThemeBackground().ignoresSafeArea())
      .liveThemeRepaint()
    .refreshable {
      async let history: Void = viewModel.loadHistory()
      async let trending: Void = viewModel.loadTrending()
      _ = await (history, trending)
    }
    .confirmationDialog(
      "Clear search history?",
      isPresented: $confirmsClear,
      titleVisibility: .visible
    ) {
      Button("Clear all", role: .destructive) {
        Task { await viewModel.clearHistory() }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This removes all saved searches from your account.")
    }
    .accessibilityIdentifier("live.search.history")
  }

  private var historySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Recent searches")
          .font(.headline)
        Spacer()
        Button("Clear") {
          confirmsClear = true
        }
        .font(.subheadline)
      }
      ForEach(viewModel.history) { item in
        Button {
          Task { await viewModel.submit(item.term) }
        } label: {
          Label(item.term, systemImage: "clock.arrow.circlepath")
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.primary)
      }
      if viewModel.canLoadMoreHistory {
        Button("Load more") {
          Task { await viewModel.loadMoreHistory() }
        }
      }
    }
  }

  @ViewBuilder
  private var trendingSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Trending on \(selectedServiceName)")
        .font(.headline)

      if viewModel.isLoadingTrending, viewModel.trending.isEmpty {
        ProgressView("Loading trending videos")
          .frame(maxWidth: .infinity)
          .padding(.vertical, 40)
      } else if let error = viewModel.trendingError,
        viewModel.trending.isEmpty {
        ContentUnavailableView {
          Label(
            "Trending unavailable",
            systemImage: "chart.line.downtrend.xyaxis"
          )
        } description: {
          Text(error)
        } actions: {
          Button("Try again") {
            Task { await viewModel.loadTrending() }
          }
        }
      } else if viewModel.trending.isEmpty {
        ContentUnavailableView(
          "Search TypeType",
          systemImage: "magnifyingglass",
          description: Text(
            "Find videos, channels, and playlists on any service."
          )
        ).liveThemedEmptyState()
      } else {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
          ForEach(viewModel.visibleTrending) { video in
            LiveVideoCard(
              video: video,
              deArrowStore: dependencies.deArrowStore,
              onChannel: {
                guard !video.uploaderURL.isEmpty else { return }
                onChannel(video.uploaderURL)
              },
              action: { onVideo(video) }
            )
            .liveVideoQuickActions(
              video: video,
              dependencies: dependencies,
              onOpenChannel: {
                guard !video.uploaderURL.isEmpty else { return }
                onChannel(video.uploaderURL)
              }
            )
          }
          DemoIncrementalLoadingTrigger(
            canLoadMore: viewModel.canLoadMoreTrending,
            isLoading: false,
            label: "Show more trending videos",
            identifier: "live.search.trending-more"
          ) {
            viewModel.revealMoreTrending()
          }
        }
      }
    }
  }

  private var selectedServiceName: String {
    viewModel.services.first {
      $0.id == viewModel.selectedServiceID
    }?.name ?? "TypeType"
  }

  private var columns: [GridItem] {
    [
      GridItem(
        .adaptive(minimum: 300, maximum: 520),
        spacing: 20,
        alignment: .top
      ),
    ]
  }
}
