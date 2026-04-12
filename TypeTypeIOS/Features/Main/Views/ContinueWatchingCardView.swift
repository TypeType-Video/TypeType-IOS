import SwiftUI

struct ContinueWatchingCardView: View {
  let item: ContinueWatchingItem

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      AsyncImage(url: URL(string: item.thumbnail)) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        Color.secondary.opacity(0.2)
      }
      .frame(width: 176, height: 100)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .overlay(alignment: .bottom) {
        GeometryReader { proxy in
          RoundedRectangle(cornerRadius: 1)
            .fill(TypeTypeColor.accent)
            .frame(width: proxy.size.width * item.progressRatio, height: 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
      }

      Text(item.title)
        .font(.caption.weight(.semibold))
        .lineLimit(2)
      Text(item.channelName)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .frame(width: 176, alignment: .leading)
  }
}
