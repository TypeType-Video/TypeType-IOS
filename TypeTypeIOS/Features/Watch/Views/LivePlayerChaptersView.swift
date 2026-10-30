import SwiftUI

struct LivePlayerChaptersView: View {
  @Environment(\.themePalette) private var palette
  @ObservedObject var controller: LivePlayerController
  var onSelect: () -> Void

  var body: some View {
    NavigationStack {
      ScrollViewReader { proxy in
        List {
          LiveSection {
            ForEach(controller.displayedChapters) { chapter in
              row(chapter)
                .id(chapter.id)
            }
          }
        }
        .liveGroupedList()
        .contentMargins(.top, 4, for: .scrollContent)
        .onAppear {
          if let current = currentChapter { proxy.scrollTo(current.id, anchor: .center) }
        }
      }
      .navigationTitle("Chapters")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", action: onSelect)
        }
      }
    }
    .accessibilityIdentifier("live.player.chapters")
  }

  private var currentChapter: LivePlaybackChapter? {
    LivePlaybackChapterNavigator.currentIndex(in: controller.displayedChapters, at: controller.position)
      .map { controller.displayedChapters[$0] }
  }

  private func row(_ chapter: LivePlaybackChapter) -> some View {
    let isCurrent = currentChapter?.id == chapter.id
    return Button {
      controller.seek(to: LivePlaybackChapterNavigator.seekTarget(for: chapter))
      onSelect()
    } label: {
      HStack(spacing: 12) {
        if let preview = chapter.previewURL.flatMap(URL.init(string:)) {
          LiveRemoteImage(url: preview)
            .frame(width: 96, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
        }
        VStack(alignment: .leading, spacing: 2) {
          Text(LivePlaybackChapterNavigator.timeText(for: chapter))
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
          Text(chapter.title)
            .font(.subheadline.weight(isCurrent ? .semibold : .regular))
            .foregroundStyle(isCurrent ? palette.accent : .primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }
        Spacer(minLength: 0)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Chapter \(LivePlaybackChapterNavigator.timeText(for: chapter)), \(chapter.title)")
    .accessibilityHint("Seeks to this chapter")
    .accessibilityAddTraits(isCurrent ? .isSelected : [])
  }
}
