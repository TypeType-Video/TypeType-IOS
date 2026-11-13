import SwiftUI

struct LivePlaybackQueueSheet: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  @Environment(\.dismiss) private var dismiss
  @State private var upcomingOverride: Bool?

  var body: some View {
    NavigationStack {
      List {
        Section {
          ForEach(
            Array(coordinator.queue.videos.enumerated().prefix(shownCount)),
            id: \.element.url
          ) { index, video in
            LivePlaybackQueueRow(
              video: video,
              isCurrent: index == coordinator.queue.currentIndex,
              onPlay: {
                coordinator.play(index: index)
                dismiss()
              },
              onPlayNext: {
                coordinator.playNext(index: index)
              },
              onRemove: {
                coordinator.remove(index: index)
              }
            )
          }
        } header: {
          header
        }
      }
        .liveThemedList()
      .listStyle(.plain)
      .navigationTitle("Playback queue")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { toolbar }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .accessibilityIdentifier("live.playback.queue.sheet")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(
        coordinator.queue.title.isEmpty
          ? "Playback queue"
          : coordinator.queue.title
      )
      .font(.headline)
      HStack {
        Text("\(coordinator.queue.videos.count) videos")
          .font(.caption)
        Spacer()
        if hasUpcoming {
          Button(upcomingHidden ? LocalizedStringKey("Show upcoming") : "Hide upcoming", systemImage: upcomingHidden ? "eye" : "eye.slash") {
            upcomingOverride = !upcomingHidden
          }
          .font(.caption)
          .accessibilityIdentifier("live.playback.queue.upcoming")
        }
      }
    }
    .textCase(nil)
  }

  private var hasUpcoming: Bool {
    coordinator.queue.currentIndex + 1 < coordinator.queue.videos.count
  }

  private var upcomingHidden: Bool {
    upcomingOverride ?? coordinator.controller?.settings.hidesUpcomingPlaylistVideos ?? false
  }

  private var shownCount: Int {
    upcomingHidden ? coordinator.queue.currentIndex + 1 : coordinator.queue.videos.count
  }

  @ToolbarContentBuilder
  private var toolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarLeading) {
      Button(action: coordinator.shuffleUpcoming) {
        Image(systemName: "shuffle")
      }
      .disabled(
        coordinator.queue.videos.count
          - coordinator.queue.currentIndex <= 2
      )
      .accessibilityLabel("Shuffle upcoming")

      Button(action: coordinator.cycleRepeatMode) {
        Image(systemName: coordinator.queue.repeatMode.symbol)
          .symbolVariant(
            coordinator.queue.repeatMode == .off ? .none : .fill
          )
      }
      .accessibilityLabel(coordinator.queue.repeatMode.title)
    }
    ToolbarItemGroup(placement: .topBarTrailing) {
      Menu {
        Button(
          "Clear queue",
          systemImage: "trash",
          role: .destructive
        ) {
          coordinator.clearQueueKeepingPlayback()
          dismiss()
        }
      } label: {
        Image(systemName: "ellipsis.circle")
      }
      Button("Done") { dismiss() }
    }
  }
}
