import SwiftUI

struct NotificationRowView: View {
  let item: NotificationItem

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      AsyncImage(url: URL(string: item.channelAvatarUrl)) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        Color.secondary.opacity(0.2)
      }
      .frame(width: 34, height: 34)
      .clipShape(Circle())

      VStack(alignment: .leading, spacing: 4) {
        Text(item.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
        Text(item.channelName)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 4)
  }
}
