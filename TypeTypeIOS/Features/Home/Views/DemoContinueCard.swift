import SwiftUI

struct DemoContinueCard: View {
  @EnvironmentObject private var session: DemoSessionStore
  let video: DemoVideo

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      DemoArtworkView(video: displayVideo)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .bottom) {
          progressBar
        }

      Text(displayVideo.title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .lineLimit(2)
        .multilineTextAlignment(.leading)

      HStack(spacing: 8) {
        DemoChannelAvatar(name: video.channel, artwork: video.artwork)
        Text(video.channel)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Spacer(minLength: 4)
        Image(systemName: "ellipsis")
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 248, alignment: .leading)
    .contentShape(Rectangle())
  }

  private var progressBar: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Color.white.opacity(0.24)
        Color(red: 1, green: 0.32, blue: 0.36)
          .frame(width: proxy.size.width * (video.progress ?? 0))
      }
    }
    .frame(height: 3)
  }

  private var displayVideo: DemoVideo {
    video.branded(using: session.preferences)
  }
}
