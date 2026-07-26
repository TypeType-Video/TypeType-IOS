import SwiftUI

struct DemoCompactVideoRow: View {
  @EnvironmentObject private var session: DemoSessionStore
  let video: DemoVideo
  let identifier: String
  let showsChannel: Bool
  let onSelect: (DemoVideo) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Button {
        onSelect(video)
      } label: {
        DemoArtworkView(video: displayVideo)
          .frame(width: 148, height: 83)
          .overlay(alignment: .bottomTrailing) {
            durationBadge
          }
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier(identifier)

      Button {
        onSelect(video)
      } label: {
        VStack(alignment: .leading, spacing: 5) {
          Text(displayVideo.title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(primaryText)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          if showsChannel {
            HStack(spacing: 5) {
              DemoChannelAvatar(
                name: video.channel,
                artwork: video.artwork,
                size: 18
              )
              Text(video.channel)
                .lineLimit(1)
            }
            .font(.caption)
            .foregroundStyle(secondaryText)
          }

          Text(video.metadata)
            .font(.caption2)
            .foregroundStyle(secondaryText)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      DemoVideoCardOptions(video: video)
        .frame(width: 30)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 3)
  }

  private var displayVideo: DemoVideo {
    video.branded(using: session.preferences)
  }

  private var durationBadge: some View {
    Text(video.duration)
      .font(.caption2.monospacedDigit().weight(.semibold))
      .foregroundStyle(.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(.black.opacity(0.86))
      .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
      .padding(6)
      .accessibilityLabel("Duration \(video.duration)")
  }

  private var primaryText: Color {
    .primary
  }

  private var secondaryText: Color {
    .secondary
  }
}
