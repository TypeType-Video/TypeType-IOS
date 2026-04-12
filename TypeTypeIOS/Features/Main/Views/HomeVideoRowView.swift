import SwiftUI

struct HomeVideoRowView: View {
  let video: HomeVideoItem

  private var viewCountText: String {
    if video.viewCount >= 1_000_000 {
      return String(format: "%.1fM", Double(video.viewCount) / 1_000_000)
    }
    if video.viewCount >= 1_000 {
      return String(format: "%.1fK", Double(video.viewCount) / 1_000)
    }
    return "\(video.viewCount)"
  }

  private var durationText: String {
    guard video.duration > 0 else { return "--:--" }
    let totalMinutes = video.duration / 60
    let seconds = video.duration % 60
    if totalMinutes >= 60 {
      let hours = totalMinutes / 60
      let minutes = totalMinutes % 60
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%02d:%02d", totalMinutes, seconds)
  }

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      AsyncImage(url: URL(string: video.thumbnailUrl)) { image in
        image
          .resizable()
          .scaledToFill()
      } placeholder: {
        Color.secondary.opacity(0.2)
      }
      .frame(width: 138, height: 78)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .overlay(alignment: .topLeading) {
        if video.isShortFormContent {
          Text("SHORT")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.black.opacity(0.7))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .padding(6)
        }
      }
      .overlay(alignment: .bottomTrailing) {
        Text(durationText)
          .font(.caption2.weight(.semibold))
          .padding(.horizontal, 6)
          .padding(.vertical, 3)
          .background(.black.opacity(0.75))
          .foregroundStyle(.white)
          .clipShape(Capsule())
          .padding(6)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(video.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)

        HStack(spacing: 4) {
          Text(video.uploaderName)
          if video.uploaderVerified {
            Image(systemName: "checkmark.seal.fill")
              .foregroundStyle(TypeTypeColor.accent)
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        HStack(spacing: 6) {
          Text("\(viewCountText) views")
          Text("•")
          Text(video.uploadDate)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 6)
  }
}
