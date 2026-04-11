import SwiftUI

struct PlaylistVideoRowView: View {
  let item: PlaylistVideoEntry

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
        Text("Position \(item.position + 1)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 4)
  }
}
