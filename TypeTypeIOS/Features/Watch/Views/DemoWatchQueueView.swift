import SwiftUI

struct DemoWatchQueueView: View {
  @EnvironmentObject private var session: DemoSessionStore
  @Environment(\.colorScheme) private var colorScheme
  let onSelect: (DemoVideo) -> Void
  @State private var presentsQueue = false
  @State private var isShuffled = false

  var body: some View {
    Button {
      presentsQueue = true
    } label: {
      HStack(spacing: 13) {
        Image(systemName: "text.line.first.and.arrowtriangle.forward")
          .font(.title3)
          .foregroundStyle(.tint)
          .frame(width: 42, height: 42)
          .background(.tint.opacity(0.14), in: Circle())
        VStack(alignment: .leading, spacing: 3) {
          Text("Playback queue")
            .font(.headline)
          Text(queueSummary)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .foregroundStyle(.primary)
      .padding(14)
      .background(surfaceColor)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
    .sheet(isPresented: $presentsQueue) {
      DemoPlaybackQueueSheet(
        videos: displayQueue,
        isShuffled: $isShuffled,
        onSelect: {
          presentsQueue = false
          onSelect($0)
        }
      )
    }
    .accessibilityIdentifier("demo.watch.queue")
  }

  private var queueSummary: String {
    guard let next = displayQueue.first else {
      return "Queue is empty"
    }
    return "\(displayQueue.count) videos · Next: \(next.title)"
  }

  private var surfaceColor: Color {
    colorScheme == .dark
      ? Color.white.opacity(0.075)
      : Color.black.opacity(0.055)
  }

  private var displayQueue: [DemoVideo] {
    let catalog = DemoSearchCatalog.videos + DemoWatchCatalog.queue
    let unique = Dictionary(
      catalog.map { ($0.id, $0) },
      uniquingKeysWith: { first, _ in first }
    )
    let ordered = session.queueOrder.compactMap { unique[$0] }
    return isShuffled ? Array(ordered.reversed()) : ordered
  }
}

private struct DemoPlaybackQueueSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var session: DemoSessionStore
  let videos: [DemoVideo]
  @Binding var isShuffled: Bool
  let onSelect: (DemoVideo) -> Void

  var body: some View {
    NavigationStack {
      Group {
        if videos.isEmpty {
          ContentUnavailableView(
            "Queue is empty",
            systemImage: "text.badge.minus",
            description: Text("Add a video from any card menu.")
          ).liveThemedEmptyState()
        } else {
          List(Array(videos.enumerated()), id: \.element.id) { index, video in
            DemoPlaybackQueueRow(
              index: index,
              video: video,
              count: videos.count,
              onSelect: { onSelect(video) }
            )
          }
          .listStyle(.plain)
        }
      }
      .navigationTitle("Playback queue")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            isShuffled.toggle()
          } label: {
            Label(
              isShuffled ? "Restore order" : "Shuffle",
              systemImage: isShuffled ? "shuffle.circle.fill" : "shuffle"
            )
          }
          .disabled(videos.count < 2)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
          Menu {
            Button("Clear queue", systemImage: "trash", role: .destructive) {
              session.clearQueue()
            }
            .disabled(videos.isEmpty)
          } label: {
            Image(systemName: "ellipsis.circle")
          }
          .accessibilityIdentifier("demo.watch.queue.actions")
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .preferredColorScheme(session.preferences.colorScheme)
    .accessibilityIdentifier("demo.watch.queue.sheet")
  }
}
