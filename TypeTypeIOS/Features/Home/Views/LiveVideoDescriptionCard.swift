import SwiftUI

struct LiveVideoDescriptionCard: View {
  let video: LiveVideoItem
  let text: String
  let onSeekTimestamp: (TimeInterval) -> Void
  let onOpenURL: (URL) -> Void
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      Text(summary)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .accessibilityIdentifier("live.video.statistics")

      InteractiveText(
        text: text,
        font: .subheadline,
        lineLimit: isCollapsed ? 3 : nil,
        onSeekTimestamp: onSeekTimestamp,
        onOpenURL: onOpenURL
      )
      .foregroundStyle(.secondary)
      .textSelection(.enabled)

      if canExpand {
        Button {
          withAnimation(.snappy(duration: 0.22)) {
            isExpanded.toggle()
          }
        } label: {
          HStack(spacing: 5) {
            Text(isExpanded ? "Show less" : "Show more")
            Image(
              systemName: isExpanded
                ? "chevron.up"
                : "chevron.down"
            )
            .font(.caption2.weight(.bold))
          }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .accessibilityIdentifier("live.video.description.toggle")
      }

      if isExpanded, !fullPublication.isEmpty {
        Text("Published \(fullPublication)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(14)
    .background(DemoTheme.surface)
    .clipShape(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
    )
  }

  private var isCollapsed: Bool {
    canExpand && !isExpanded
  }

  private var canExpand: Bool {
    text.count > 120
      || text.filter { $0.isNewline }.count > 2
  }

  private var summary: String {
    var values = [
      LiveVideoMetadataFormatter.views(video.viewCount),
      LiveVideoMetadataFormatter.publication(video),
    ]
    if video.isLive {
      values.insert(String(localized: "Live"), at: 0)
    }
    return values.filter { !$0.isEmpty }.joined(separator: " · ")
  }

  private var fullPublication: String {
    LiveVideoMetadataFormatter.fullPublication(video)
  }
}
