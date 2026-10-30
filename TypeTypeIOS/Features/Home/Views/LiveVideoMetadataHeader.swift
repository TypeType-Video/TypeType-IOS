import SwiftUI

struct LiveVideoMetadataHeader: View {
  let video: LiveVideoItem
  let title: String
  let description: String?
  let onSeekTimestamp: (TimeInterval) -> Void
  let onOpenURL: (URL) -> Void
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Button {
        withAnimation(.snappy(duration: 0.22)) { isExpanded.toggle() }
      } label: {
        VStack(alignment: .leading, spacing: 6) {
          Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
            .lineLimit(isExpanded ? nil : 2)
            .multilineTextAlignment(.leading)
          subtitle
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint(isExpanded ? "Hides the description" : "Shows the description")
      .accessibilityIdentifier("live.video.description.toggle")

      if isExpanded {
        expandedDetails
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 14)
          .transition(.opacity)
      }
    }
  }

  private var subtitle: some View {
    HStack(spacing: 16) {
      if video.isLive {
        Text("LIVE")
          .font(.caption2.weight(.bold))
          .foregroundStyle(.white)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Color.red, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
          .accessibilityLabel("Live")
      }
      let published = LiveVideoMetadataFormatter.publication(video)
      if !published.isEmpty {
        Text(published)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 8)
      Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("live.video.statistics")
  }

  private var expandedDetails: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let description, !description.isEmpty {
        InteractiveText(
          text: description,
          font: .body,
          lineLimit: nil,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
        .lineSpacing(4)
        .textSelection(.enabled)
      }
      let published = LiveVideoMetadataFormatter.fullPublication(video)
      if !published.isEmpty {
        Text("Published \(published)")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }
}
