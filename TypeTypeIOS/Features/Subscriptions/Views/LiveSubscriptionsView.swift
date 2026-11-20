import SwiftUI

struct LiveSubscriptionsView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject var viewModel: LiveSubscriptionsViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedVideoChannelURL: String?
  @State var selectedChannel: LiveSubscription?
  @State var isShowingGroups = false
  @State var channelQuery = ""

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: LiveSubscriptionsViewModel(
        service: coordinator.dependencies.subscriptionsService
      )
    )
  }

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Subscriptions")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
          Picker("Subscriptions", selection: $viewModel.section) {
            ForEach(LiveSubscriptionsViewModel.Section.allCases) {
              Text($0.title).tag($0)
            }
          }
          .pickerStyle(.segmented)
          .frame(maxWidth: 480)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(.bar)
          .accessibilityIdentifier("live.subscriptions.section")
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            LiveSubscriptionFilterMenu(viewModel: viewModel)
          }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isShowingGroups = true
          } label: {
            Image(systemName: "square.stack.3d.up.fill")
          }
          .disabled(viewModel.state != .loaded)
          .accessibilityLabel("Manage subscription groups")
          .accessibilityIdentifier("live.subscriptions.groups")
        }
      }
        .onChange(of: selectedVideo) { _, video in
          guard let video else { return }
          selectedVideo = nil
          coordinator.dependencies.playbackCoordinator.open(video)
        }
        .navigationDestination(
          item: $selectedVideoChannelURL
        ) { channelURL in
          LiveChannelView(
            channelURL: channelURL,
            dependencies: coordinator.dependencies
          )
        }
        .navigationDestination(item: $selectedChannel) { channel in
          LiveChannelView(
            channelURL: channel.channelURL,
            dependencies: coordinator.dependencies
          )
        }
        .navigationDestination(isPresented: $isShowingGroups) {
          LiveSubscriptionGroupsView(viewModel: viewModel)
        }
    }
    .task { await viewModel.prepare() }
    .accessibilityIdentifier("live.subscriptions.screen")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .cards)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView {
        Label("Subscriptions unavailable", systemImage: "wifi.exclamationmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      loadedContent
    }
  }

  @ViewBuilder
  private var loadedContent: some View {
    switch viewModel.section {
    case .videos:
      videoFeed
    case .channels:
      channelList
    }
  }

  private var videoFeed: some View {
    Group {
      if viewModel.visibleVideos.isEmpty {
        ContentUnavailableView(
          "No subscription videos",
          systemImage: "bell.slash",
          description: Text("Subscribe to a channel to build this feed.")
        ).liveThemedEmptyState()
      } else {
        ScrollView {
          LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
            ForEach(viewModel.visibleVideos) { video in
              LiveVideoCard(
                video: video,
                deArrowStore:
                  coordinator.dependencies.deArrowStore,
                onChannel: {
                  guard !video.uploaderURL.isEmpty else { return }
                  selectedVideoChannelURL = video.uploaderURL
                },
                action: { selectedVideo = video }
              )
              .liveVideoQuickActions(
                video: video,
                dependencies: coordinator.dependencies,
                onOpenChannel: {
                  guard !video.uploaderURL.isEmpty else { return }
                  selectedVideoChannelURL = video.uploaderURL
                }
              )
            }
            LiveIncrementalLoadingTrigger(
              canLoadMore: viewModel.canLoadMore,
              isLoading: viewModel.isLoadingMore,
              label: "Loading more subscriptions",
              identifier: "live.subscriptions.loading-more"
            ) {
              Task { await viewModel.loadMore() }
            }
          }
          .padding(16)
        }
        .refreshable { await viewModel.reload() }
      }
    }
    .background(LiveThemeBackground().ignoresSafeArea())
    .accessibilityIdentifier("live.subscriptions.videos")
  }

  private var columns: [GridItem] {
    [
      GridItem(
        .adaptive(minimum: 330, maximum: 520),
        spacing: 22,
        alignment: .top
      ),
    ]
  }
}
