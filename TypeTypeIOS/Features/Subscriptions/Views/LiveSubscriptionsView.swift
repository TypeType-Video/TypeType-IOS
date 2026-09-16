import SwiftUI

struct LiveSubscriptionsView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: LiveSubscriptionsViewModel
  @State private var selectedVideo: LiveVideoItem?
  @State private var selectedVideoChannelURL: String?
  @State private var selectedChannel: LiveSubscription?
  @State private var isShowingGroups = false

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
        .toolbar {
          ToolbarItem(placement: .principal) {
            Picker("Subscriptions", selection: $viewModel.section) {
              ForEach(LiveSubscriptionsViewModel.Section.allCases) {
                Text($0.title).tag($0)
              }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            .accessibilityIdentifier("live.subscriptions.section")
          }
          ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Button {
              Task { await viewModel.selectFilter(.all) }
            } label: {
              Label("All subscriptions", systemImage: "square.grid.2x2")
            }
            Button {
              Task { await viewModel.selectFilter(.ungrouped) }
            } label: {
              Label("Ungrouped", systemImage: "tray")
            }
            if !viewModel.groups.isEmpty {
              Section("Groups") {
                ForEach(viewModel.groups) { group in
                  Button(group.name) {
                    Task {
                      await viewModel.selectFilter(.group(
                        id: group.id,
                        name: group.name
                      ))
                    }
                  }
                }
              }
            }
          } label: {
            Image(systemName: "folder.badge.gearshape")
          }
          .disabled(viewModel.state != .loaded)
          .accessibilityLabel("Subscription filter")
          .accessibilityValue(viewModel.filterLabel)
          .accessibilityIdentifier("live.subscriptions.filter")
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
        .navigationDestination(item: $selectedVideo) { video in
          LiveVideoMetadataView(
            video: video,
            dependencies: coordinator.dependencies
          )
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
      ProgressView("Loading subscriptions")
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
        )
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
            DemoIncrementalLoadingTrigger(
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
    .background(DemoTheme.background)
    .accessibilityIdentifier("live.subscriptions.videos")
  }

  private var channelList: some View {
    Group {
      if viewModel.channels.isEmpty {
        ContentUnavailableView(
          "No subscriptions",
          systemImage: "person.2.slash",
          description: Text("Channels you subscribe to will appear here.")
        )
      } else {
        List(viewModel.channels) { channel in
          LiveSubscriptionChannelRow(
            channel: channel,
            onOpen: { selectedChannel = channel },
            onUnsubscribe: {
              Task { await viewModel.unsubscribe(channel) }
            }
          ) { channel in
            AnyView(groupQuickActions(for: channel))
          }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.reload() }
      }
    }
    .accessibilityIdentifier("live.subscriptions.channels")
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

  @ViewBuilder
  private func groupQuickActions(
    for channel: LiveSubscription
  ) -> some View {
    Section("Groups") {
      if viewModel.groups.isEmpty {
        Text("No groups")
      } else {
        ForEach(viewModel.groups) { group in
          let isMember = viewModel.groupIDs(for: channel.channelURL)
            .contains(group.id)
          Button {
            Task {
              await viewModel.toggleGroupMembership(channel, in: group)
            }
          } label: {
            if isMember {
              Label(
                "Remove from \(group.name)",
                systemImage: "minus.circle"
              )
            } else {
              Label(
                "Add to \(group.name)",
                systemImage: "plus.circle"
              )
            }
          }
        }
      }
    }
  }
}
