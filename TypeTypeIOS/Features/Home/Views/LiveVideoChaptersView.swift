import SwiftUI

struct LiveVideoChaptersView: View {
  let chapters: [LivePlaybackChapter]
  let onSeek: (TimeInterval) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Chapters")
        .font(.title3.weight(.bold))
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
          ForEach(chapters) { chapter in
            Button {
              onSeek(TimeInterval(chapter.startTimeSeconds))
            } label: {
              VStack(alignment: .leading, spacing: 3) {
                Text(chapter.title)
                  .font(.subheadline.weight(.semibold))
                  .lineLimit(1)
                Text(
                  LiveVideoMetadataFormatter.duration(
                    Int64(chapter.startTimeSeconds)
                  )
                )
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
              }
              .padding(.horizontal, 13)
              .padding(.vertical, 10)
              .background(
                DemoTheme.surface,
                in: RoundedRectangle(cornerRadius: 12)
              )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(
              "live.video.chapter.\(chapter.startTimeSeconds)"
            )
          }
        }
      }
      .accessibilityIdentifier("live.video.chapters")
    }
  }
}
