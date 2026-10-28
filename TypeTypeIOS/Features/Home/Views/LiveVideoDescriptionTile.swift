import SwiftUI

/// Slim collapsible description tile (dev feedback, plan task 3.2): the
/// watch page reads title → channel → actions without a wall of text.
/// One tap expands the full description in place, tapping again collapses.
struct LiveVideoDescriptionTile: View {
  let video: LiveVideoItem
  let text: String
  let likeCount: Int64
  let onSeekTimestamp: (TimeInterval) -> Void
  let onOpenURL: (URL) -> Void
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      // The like-count display survives the collapse (dev spec).
      Text(summary)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .accessibilityIdentifier("live.video.statistics")

      Button {
        withAnimation(.snappy(duration: 0.22)) {
          isExpanded.toggle()
        }
      } label: {
        HStack(spacing: 5) {
          Text("Description")
          Image(
            systemName: isExpanded
              ? "chevron.up"
              : "chevron.down"
          )
          .font(.caption2.weight(.bold))
        }
        .contentShape(Rectangle())
      }
      .font(.caption.weight(.semibold))
      .foregroundStyle(.primary)
      .accessibilityIdentifier("live.video.description.toggle")

      if isExpanded {
        InteractiveText(
          text: text,
          font: .subheadline,
          lineLimit: nil,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
        .foregroundStyle(.secondary)
        .textSelection(.enabled)

        if !fullPublication.isEmpty {
          Text("Published \(fullPublication)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(DemoTheme.groupedSurface)
    .clipShape(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
    )
  }

  private var summary: String {
    var values = [
      LiveVideoMetadataFormatter.views(video.viewCount),
    ]
    if likeCount >= 0 {
      values.append(
        LiveVideoMetadataFormatter.compactCount(likeCount) + " likes"
      )
    }
    values.append(LiveVideoMetadataFormatter.publication(video))
    if video.isLive {
      values.insert(String(localized: "Live"), at: 0)
    }
    return values.filter { !$0.isEmpty }.joined(separator: " · ")
  }

  private var fullPublication: String {
    LiveVideoMetadataFormatter.fullPublication(video)
  }
}
