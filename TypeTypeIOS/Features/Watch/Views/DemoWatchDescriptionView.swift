import SwiftUI

struct DemoWatchDescriptionView: View {
  @EnvironmentObject var session: DemoSessionStore
  let video: DemoVideo
  @ObservedObject var controller: DemoPlayerController
  let onOpenURL: (URL) -> Void
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Button {
        withAnimation(.snappy(duration: 0.24)) {
          isExpanded.toggle()
        }
      } label: {
        HStack {
          VStack(alignment: .leading, spacing: 3) {
            Text("About this video")
              .font(.headline)
            Text("1.2M views · published May 30, 2008")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          Spacer()
          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      InteractiveText(
        text: description,
        font: .subheadline,
        lineLimit: isExpanded ? nil : 3,
        onSeekTimestamp: controller.seek(to:),
        onOpenURL: onOpenURL
      )
        .foregroundStyle(.secondary)

      if isExpanded {
        Divider()
        chapters
        Divider()
        metadata
        externalLinks
      } else {
        Button("Show more") {
          withAnimation(.snappy) {
            isExpanded = true
          }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      }
    }
    .padding(16)
    .foregroundStyle(.primary)
    .background(DemoTheme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .accessibilityIdentifier("demo.watch.description")
  }

  private var chapters: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Chapters", systemImage: "list.bullet.rectangle")
        .font(.subheadline.weight(.semibold))

      ScrollView(.horizontal) {
        HStack(spacing: 9) {
          ForEach(visibleChapters) { chapter in
            Button {
              controller.seek(to: chapter.seconds)
            } label: {
              VStack(alignment: .leading, spacing: 4) {
                Text(chapter.timestamp)
                  .font(.caption2.monospacedDigit().weight(.semibold))
                  .foregroundStyle(Color(red: 1, green: 0.31, blue: 0.34))
                Text(chapter.title)
                  .font(.caption)
                  .foregroundStyle(.primary)
                  .lineLimit(1)
              }
              .padding(10)
              .frame(width: 158, alignment: .leading)
              .background(DemoTheme.elevatedSurface)
              .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .buttonStyle(.plain)
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }
  private var description: String {
    if video.id.contains("big-buck") {
      return
        "Big Buck Bunny tells the story of a giant rabbit with a heart bigger "
        + "than himself. When three rodents disturb his peaceful morning, he prepares "
        + "a surprising lesson. This open movie and its production files were released "
        + "by the Blender Foundation. Jump to 1:44 or open the original "
        + "https://www.youtube.com/watch?v=YE7VzlLtp-4 without leaving TypeType."
    }
    return
      "\(video.title) is presented here with TypeType's native iOS watch experience. "
      + "This local mock keeps every interaction available while the production data "
      + "and SABR playback contract are connected. Revisit 1:44 or resolve "
      + "https://www.nicovideo.jp/watch/sm9 directly inside TypeType."
  }
}
