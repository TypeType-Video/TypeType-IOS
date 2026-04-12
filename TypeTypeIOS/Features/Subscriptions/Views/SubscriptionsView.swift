import SwiftUI

struct SubscriptionsView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: SubscriptionsViewModel

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: SubscriptionsViewModel(service: coordinator.dependencies.subscriptionsService)
    )
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 10) {
        Picker("Mode", selection: $viewModel.mode) {
          Text("Feed").tag(SubscriptionsViewModel.Mode.feed)
          Text("Channels").tag(SubscriptionsViewModel.Mode.channels)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)

        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
            .font(.footnote)
            .foregroundStyle(.red)
            .padding(.horizontal)
        }

        switch viewModel.mode {
        case .feed:
          feedList
        case .channels:
          channelsList
        }
      }
      .navigationTitle("Subscriptions")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            Task { await viewModel.refreshCurrent() }
          } label: {
            Image(systemName: "arrow.clockwise")
          }
        }
      }
    }
    .task {
      await viewModel.loadInitial()
    }
  }

  @ViewBuilder
  private var feedList: some View {
    if viewModel.isLoadingFeed && viewModel.feedVideos.isEmpty {
      ProgressView("Loading subscriptions feed...")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    } else if viewModel.feedVideos.isEmpty {
      ContentUnavailableView(
        "No subscription videos yet",
        systemImage: "dot.radiowaves.left.and.right",
        description: Text("Subscribe to channels and refresh this tab.")
      )
    } else {
      List {
        ForEach(viewModel.feedVideos) { video in
          NavigationLink {
            WatchView(
              videoURL: video.url,
              coordinator: coordinator,
              watchService: coordinator.dependencies.watchService,
              watchProgressService: coordinator.dependencies.watchProgressService,
              watchActionsService: coordinator.dependencies.watchActionsService
            )
          } label: {
            SubscriptionsFeedRow(video: video)
          }
        }

        if viewModel.canLoadMoreFeed {
          if viewModel.isLoadingMoreFeed {
            ProgressView()
              .frame(maxWidth: .infinity)
          } else {
            Button("Load more") {
              Task { await viewModel.loadMoreFeed() }
            }
            .frame(maxWidth: .infinity)
          }
        }
      }
      .listStyle(.plain)
      .refreshable { await viewModel.reloadFeed() }
    }
  }

  @ViewBuilder
  private var channelsList: some View {
    if viewModel.isLoadingChannels && viewModel.channels.isEmpty {
      ProgressView("Loading subscriptions...")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    } else if viewModel.channels.isEmpty {
      ContentUnavailableView(
        "No subscriptions yet",
        systemImage: "person.2",
        description: Text("Start subscribing from watch pages.")
      )
    } else {
      List {
        ForEach(viewModel.channels) { channel in
          SubscriptionsChannelRow(channel: channel)
            .swipeActions(edge: .trailing) {
              Button("Unsubscribe", role: .destructive) {
                Task { await viewModel.remove(channel: channel) }
              }
            }
        }
      }
      .listStyle(.plain)
      .refreshable { await viewModel.reloadChannels() }
    }
  }
}
