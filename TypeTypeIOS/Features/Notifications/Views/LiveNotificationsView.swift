import SwiftUI

struct LiveNotificationsView: View {
  @Environment(\.themePalette) private var palette
  let dependencies: AppDependencies
  @StateObject private var viewModel: LiveNotificationsViewModel
  @State private var selectedVideo: LiveVideoItem?
  @State private var presentsSettings = false

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
          Menu {
            Button("Mark all read") {
              Task { await viewModel.markAllRead() }
            }
            .disabled(
              viewModel.unreadCount == 0 || viewModel.isMarkingRead
            )
            if dependencies.pushNotificationsEnabled {
              Button("Channel notifications") {
                presentsSettings = true
              }
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
          .accessibilityLabel("Notification actions")
          .accessibilityIdentifier("live.notifications.actions")
        }
      }
      .onChange(of: selectedVideo) { _, video in
        guard let video else { return }
        selectedVideo = nil
        dependencies.playbackCoordinator.open(video)
      }
      .navigationDestination(isPresented: $presentsSettings) {
        LiveNotificationSettingsView(dependencies: dependencies)
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
      TypeTypeSkeletonList(layout: .settings, count: 8)
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
      ).liveThemedEmptyState()
    } else {
      List {
        if viewModel.unreadCount > 0 {
          Section {
            Label(
              "\(viewModel.unreadCount) unread",
              systemImage: "bell.badge.fill"
            )
            .foregroundStyle(palette.accent)
          }
        }
        Section {
          ForEach(viewModel.items) { item in
            LiveNotificationRow(
              notification: item,
              deArrowStore: dependencies.deArrowStore
            ) {
              selectedVideo = viewModel.markReadAndOpen(item)
            }
          }
          LiveIncrementalLoadingTrigger(
            canLoadMore: viewModel.canLoadMore,
            isLoading: viewModel.isLoadingMore,
            label: "Loading more notifications",
            identifier: "live.notifications.loading-more"
          ) {
            Task { await viewModel.loadMore() }
          }
        }
      }
        .liveGroupedList()
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
