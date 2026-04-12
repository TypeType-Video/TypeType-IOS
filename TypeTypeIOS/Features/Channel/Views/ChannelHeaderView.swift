import SwiftUI

struct ChannelHeaderView: View {
  let page: ChannelPage

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      AsyncImage(url: URL(string: page.bannerURL)) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        TypeTypeColor.card
      }
      .frame(height: 128)
      .clipShape(RoundedRectangle(cornerRadius: 12))

      HStack(spacing: 10) {
        AsyncImage(url: URL(string: page.avatarURL)) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          TypeTypeColor.card
        }
        .frame(width: 42, height: 42)
        .clipShape(Circle())

        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 5) {
            Text(page.name)
              .font(.headline)
            if page.isVerified {
              Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(TypeTypeColor.accent)
            }
          }
          Text("\(formattedSubscribers) subscribers")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      if !page.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text(page.description)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(3)
      }
    }
    .padding(.horizontal)
    .padding(.top, 8)
  }

  private var formattedSubscribers: String {
    if page.subscriberCount >= 1_000_000 {
      return String(format: "%.1fM", Double(page.subscriberCount) / 1_000_000)
    }
    if page.subscriberCount >= 1_000 {
      return String(format: "%.1fK", Double(page.subscriberCount) / 1_000)
    }
    return "\(page.subscriberCount)"
  }
}
