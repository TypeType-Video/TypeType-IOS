import SwiftUI

struct LibraryHistoryRowView: View {
  let item: HistoryEntry

  private var watchedAtText: String {
    guard item.watchedAt > 0 else { return "" }
    let date = Date(timeIntervalSince1970: TimeInterval(item.watchedAt / 1000))
    return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
  }

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      AsyncImage(url: URL(string: item.thumbnail)) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        Color.secondary.opacity(0.18)
      }
      .frame(width: 120, height: 68)
      .clipShape(RoundedRectangle(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 4) {
        Text(item.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
        Text(item.channelName)
          .font(.caption)
          .foregroundStyle(.secondary)
        if !watchedAtText.isEmpty {
          Text(watchedAtText)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 4)
  }
}
