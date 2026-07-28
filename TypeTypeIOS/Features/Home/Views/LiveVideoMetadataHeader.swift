import SwiftUI

struct LiveVideoMetadataHeader: View {
  let video: LiveVideoItem
  let title: String
  let description: String?
  let subscriberCount: Int64?
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
            if let subscriberCount {
              Text(
                LiveVideoMetadataFormatter.subscribers(
                  subscriberCount
                )
              )
              .font(.caption)
              .foregroundStyle(.secondary)
              .accessibilityIdentifier(
                "live.video.channel.subscribers"
              )
            }
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
        LiveVideoDescriptionCard(
          video: video,
          text: description,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
      }
    }
  }
}
