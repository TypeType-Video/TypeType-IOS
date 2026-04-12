import SwiftUI

struct NotificationsView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: NotificationsViewModel

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: NotificationsViewModel(service: coordinator.dependencies.notificationsService)
    )
  }

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isLoading && viewModel.items.isEmpty {
          ProgressView("Loading notifications...")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if viewModel.items.isEmpty {
          ContentUnavailableView(
            "No notifications",
            systemImage: "bell.slash",
            description: Text("New activity from subscriptions will appear here.")
          )
        } else {
          List {
            ForEach(viewModel.items) { item in
              VStack(alignment: .leading, spacing: 4) {
                NavigationLink {
                  WatchView(
                    videoURL: item.video.url,
                    coordinator: coordinator,
                    watchService: coordinator.dependencies.watchService,
                    watchProgressService: coordinator.dependencies.watchProgressService,
                    watchActionsService: coordinator.dependencies.watchActionsService
                  )
                } label: {
                  NotificationRowView(item: item)
                }

                NavigationLink {
                  ChannelView(channelURL: item.channelUrl, coordinator: coordinator)
                } label: {
                  Text("Open channel: \(item.channelName)")
                    .font(.caption)
                    .foregroundStyle(TypeTypeColor.accent)
                }
                .buttonStyle(.plain)
              }
            }

            if viewModel.canLoadMore {
              if viewModel.isLoadingMore {
                ProgressView()
                  .frame(maxWidth: .infinity)
              } else {
                Button("Load more") {
                  Task { await viewModel.loadMore() }
                }
                .frame(maxWidth: .infinity)
              }
            }
          }
          .listStyle(.plain)
          .refreshable {
            await viewModel.loadInitial()
          }
        }
      }
      .navigationTitle("Notifications")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          if viewModel.unreadCount > 0 {
            Text("\(viewModel.unreadCount) unread")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("Read all") {
            Task { await viewModel.markAllRead() }
          }
          .disabled(viewModel.items.isEmpty)
        }
      }
    }
    .task {
      await viewModel.loadInitial()
    }
  }
}
