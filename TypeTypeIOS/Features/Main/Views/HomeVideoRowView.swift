import SwiftUI

struct HomeVideoRowView: View {
  let video: HomeVideoItem

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      AsyncImage(url: URL(string: video.thumbnailUrl)) { image in
        image
          .resizable()
          .scaledToFill()
      } placeholder: {
        Color.secondary.opacity(0.2)
      }
      .frame(width: 120, height: 68)
      .clipShape(RoundedRectangle(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 4) {
        Text(video.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
        Text(video.uploaderName)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(video.uploadDate)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 4)
  }
}
