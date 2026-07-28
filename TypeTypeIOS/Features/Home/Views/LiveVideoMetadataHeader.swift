import SwiftUI

struct LiveVideoMetadataHeader: View {
  let video: LiveVideoItem
  let title: String
  let description: String?
  let onChannel: () -> Void
  let onSeekTimestamp: (TimeInterval) -> Void
  let onOpenURL: (URL) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.title2.weight(.bold))
        .textSelection(.enabled)

      Button(action: onChannel) {
        HStack(spacing: 8) {
          LiveRemoteImage(url: video.uploaderAvatar)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
          VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
              Text(video.uploaderName)
                .font(.subheadline.weight(.semibold))
              if video.uploaderVerified {
                Image(systemName: "checkmark.seal.fill")
                  .font(.caption)
                  .foregroundStyle(DemoTheme.accent)
                  .accessibilityLabel("Verified")
              }
            }
            Text(metadata)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
        }
      }
      .buttonStyle(.plain)
      .disabled(video.uploaderURL.isEmpty)

      if let description, !description.isEmpty {
        InteractiveText(
          text: description,
          font: .body,
          lineLimit: nil,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
      }
    }
  }

  private var metadata: String {
    var values = [
      LiveVideoMetadataFormatter.views(video.viewCount),
      LiveVideoMetadataFormatter.publication(video),
    ]
    if video.isLive {
      values.insert("Live", at: 0)
    } else {
      values.insert(
        LiveVideoMetadataFormatter.duration(video.duration),
        at: 0
      )
    }
    return values.filter { !$0.isEmpty }.joined(separator: " · ")
  }
}
