import SwiftUI

struct DemoNotificationsView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var session: DemoSessionStore
  @State private var selectedVideo: DemoVideo?
  @State private var visibleCount = 3
  @State private var isLoadingMore = false
  @State private var showsError = false

  var body: some View {
    NavigationStack {
      Group {
        if showsError {
          ContentUnavailableView {
            Label("Notifications unavailable", systemImage: "wifi.exclamationmark")
          } description: {
            Text("The local mock simulated a rate-limit error.")
          } actions: {
            Button("Retry") {
              showsError = false
            }
            .buttonStyle(.borderedProminent)
          }
        } else if session.notifications.isEmpty {
          ContentUnavailableView(
            "No notifications",
            systemImage: "bell.slash",
            description: Text("New uploads and local activity will appear here.")
          )
        } else {
          List {
            ForEach(
              Array(session.notifications.indices.prefix(visibleCount)),
              id: \.self
            ) { index in
              Button {
                session.notifications[index].isRead = true
                selectedVideo = session.notifications[index].video
              } label: {
                row(session.notifications[index])
              }
              .buttonStyle(.plain)
              .swipeActions {
                Button("Delete", role: .destructive) {
                  remove(session.notifications[index].id)
                }
              }
            }
            DemoIncrementalLoadingTrigger(
              canLoadMore: visibleCount < session.notifications.count,
              isLoading: isLoadingMore,
              label: "Loading more notifications",
              identifier: "demo.notifications.loading",
              action: loadMore
            )
          }
          .listStyle(.plain)
        }
      }
      .navigationTitle("Notifications")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close", systemImage: "xmark") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Menu {
            Button("Mark all read", systemImage: "checkmark.circle") {
              for index in session.notifications.indices {
                session.notifications[index].isRead = true
              }
            }
            .disabled(session.notifications.allSatisfy(\.isRead))
            Button("Preview loading error", systemImage: "exclamationmark.triangle") {
              showsError = true
            }
          } label: {
            Label("Notification actions", systemImage: "ellipsis.circle")
          }
        }
      }
      .navigationDestination(item: $selectedVideo) { video in
        DemoWatchView(video: video)
      }
    }
    .preferredColorScheme(session.preferences.colorScheme)
    .accessibilityIdentifier("demo.notifications.screen")
  }

  private func row(_ notification: DemoNotification) -> some View {
    HStack(alignment: .top, spacing: 13) {
      DemoChannelAvatar(
        name: notification.title,
        artwork: notification.artwork,
        size: 46
      )

      VStack(alignment: .leading, spacing: 4) {
        Text(notification.title)
          .font(.subheadline.weight(notification.isRead ? .regular : .semibold))
          .foregroundStyle(.primary)
        Text(notification.message)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
        Text(notification.timestamp)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 4)
      if !notification.isRead {
        Circle()
          .fill(Color(red: 1, green: 0.3, blue: 0.34))
          .frame(width: 8, height: 8)
          .padding(.top, 6)
      }
    }
    .padding(.vertical, 6)
  }

  private func remove(_ id: String) {
    withAnimation {
      session.notifications.removeAll { $0.id == id }
    }
  }

  private func loadMore() {
    guard !isLoadingMore, visibleCount < session.notifications.count else {
      return
    }
    isLoadingMore = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(360))
      withAnimation(.smooth(duration: 0.25)) {
        visibleCount = min(visibleCount + 3, session.notifications.count)
      }
      try? await Task.sleep(for: .milliseconds(140))
      isLoadingMore = false
    }
  }
}
