import SwiftUI

struct LiveSearchChannelCard: View {
  @Environment(\.themePalette) private var palette
  let channel: LiveChannelResult
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 14) {
        LiveRemoteImage(url: channel.thumbnail)
          .frame(width: 82, height: 82)
          .clipShape(Circle())

        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 5) {
            Text(channel.name)
              .font(.headline)
              .lineLimit(1)
            if channel.isVerified {
              Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(palette.accent)
                .accessibilityLabel("Verified")
            }
          }
          Text(
            LiveVideoMetadataFormatter.subscribers(
              channel.subscriberCount
            )
          )
          .font(.caption)
          .foregroundStyle(.secondary)
          if !channel.description.isEmpty {
            Text(channel.description)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(14)
      .background(
        palette.surface,
        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
      )
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("live.search.channel")
  }
}
