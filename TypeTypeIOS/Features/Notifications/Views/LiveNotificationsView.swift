import SwiftUI

struct LiveNotificationsView: View {
  let dependencies: AppDependencies
  @StateObject private var viewModel: LiveNotificationsViewModel
  @State private var selectedVideo: LiveVideoItem?

  init(dependencies: AppDependencies) {
    self.dependencies = dependencies
    _viewModel = StateObject(
      wrappedValue: LiveNotificationsViewModel(
        service: dependencies.notificationsService,
        notificationCenter: dependencies.notificationCenter
      )
    )
  }

  var body: some View {
    content
      .navigationTitle("Notifications")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Mark all read") {
            Task { await viewModel.markAllRead() }
          }
          .disabled(
            viewModel.unreadCount == 0 || viewModel.isMarkingRead
          )
        }
      }
      .navigationDestination(item: $selectedVideo) { video in
        LiveVideoMetadataView(video: video, dependencies: dependencies)
      }
      .task { await viewModel.prepare() }
      .alert("Notifications", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .accessibilityIdentifier("live.notifications.screen")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView("Loading notifications")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView {
        Label("Notifications unavailable", systemImage: "bell.slash")
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
    if viewModel.items.isEmpty {
      ContentUnavailableView(
        "No notifications",
        systemImage: "bell",
        description: Text("New videos from subscriptions appear here.")
      )
    } else {
      List {
        if viewModel.unreadCount > 0 {
          Section {
            Label(
              "\(viewModel.unreadCount) unread",
              systemImage: "bell.badge.fill"
            )
            .foregroundStyle(DemoTheme.accent)
          }
        }
        Section {
          ForEach(viewModel.items) { item in
            LiveNotificationRow(
              notification: item,
              deArrowStore: dependencies.deArrowStore
            ) {
              selectedVideo = item.video
            }
          }
          DemoIncrementalLoadingTrigger(
            canLoadMore: viewModel.canLoadMore,
            isLoading: viewModel.isLoadingMore,
            label: "Loading more notifications",
            identifier: "live.notifications.loading-more"
          ) {
            Task { await viewModel.loadMore() }
          }
        }
      }
      .listStyle(.plain)
      .refreshable { await viewModel.reload() }
    }
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
