import SwiftUI

struct LivePlayerChaptersView: View {
  @ObservedObject var controller: LivePlayerController
  var onSelect: (() -> Void)? = nil

  @ViewBuilder
  var body: some View {
    if controller.displayedChapters.isEmpty {
      ContentUnavailableView(
        "No chapters",
        systemImage: "list.bullet.rectangle",
        description: Text("This video has no chapters.")
      )
      .liveThemedEmptyState()
    } else {
      List(controller.displayedChapters) { chapter in
        chapterRow(chapter)
      }
      .liveThemedList()
      .navigationTitle("Chapters")
      .navigationBarTitleDisplayMode(.inline)
      .accessibilityIdentifier("live.player.chapters")
    }
  }

  private func currentChapter() -> LivePlaybackChapter? {
    let index = LivePlaybackChapterNavigator.currentIndex(
      in: controller.displayedChapters,
      at: controller.position
    )
    guard let index else { return nil }
    return controller.displayedChapters[index]
  }

  @ViewBuilder
  private func chapterRow(
    _ chapter: LivePlaybackChapter
  ) -> some View {
    let isCurrent = currentChapter()?.id == chapter.id

    Button {
      controller.seek(
        to: LivePlaybackChapterNavigator.seekTarget(for: chapter)
      )
      onSelect?()
    } label: {
      HStack(spacing: 12) {
        Text(LivePlaybackChapterNavigator.timeText(for: chapter))
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
          .monospacedDigit()

        VStack(alignment: .leading, spacing: 2) {
          Text(chapter.title)
            .font(.subheadline.weight(isCurrent ? .semibold : .regular))
            .foregroundStyle(isCurrent ? DemoTheme.accent : .primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          if let channelName = chapter.channelName {
            Text(channelName)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        Spacer(minLength: 0)

        if isCurrent {
          Image(systemName: "speaker.wave.2.fill")
            .foregroundStyle(DemoTheme.accent)
            .accessibilityLabel("Current chapter")
        }
      }
      .padding(.vertical, 2)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      "Chapter \(LivePlaybackChapterNavigator.timeText(for: chapter)), \(chapter.title)"
    )
    .accessibilityHint("Seeks to this chapter")
    .accessibilityAddTraits(isCurrent ? .isSelected : [])
  }
}
