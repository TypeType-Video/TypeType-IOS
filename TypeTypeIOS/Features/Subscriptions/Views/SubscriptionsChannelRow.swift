import SwiftUI

struct SubscriptionsChannelRow: View {
  let channel: SubscriptionChannel

  var body: some View {
    HStack(spacing: 10) {
      AsyncImage(url: URL(string: channel.avatarUrl)) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        Color.secondary.opacity(0.2)
      }
      .frame(width: 42, height: 42)
      .clipShape(Circle())

      VStack(alignment: .leading, spacing: 3) {
        Text(channel.name)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
        Text(channel.channelUrl)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 4)
  }
}
