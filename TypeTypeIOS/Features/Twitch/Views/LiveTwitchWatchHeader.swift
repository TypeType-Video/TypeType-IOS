import SwiftUI

struct LiveTwitchWatchHeader: View {
  @ObservedObject var controller: LivePlayerController
  let video: LiveVideoItem
  let onChannel: () -> Void
  let onLink: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        if controller.stream?.isLive == true {
          Text("LIVE")
            .font(.caption2.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red, in: RoundedRectangle(cornerRadius: 4))
            .accessibilityLabel(Text("Live"))
        }
        Text(verbatim: controller.stream?.title ?? video.title)
          .font(.headline)
          .lineLimit(2)
      }
      HStack(spacing: 10) {
        Button(action: onChannel) {
          HStack(spacing: 10) {
            LiveTwitchAvatar(url: controller.stream?.uploaderAvatarURL ?? video.uploaderAvatarURL, size: 36)
            VStack(alignment: .leading, spacing: 2) {
              Text(verbatim: controller.stream?.uploaderName ?? video.uploaderName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
              TimelineView(.periodic(from: .now, by: 60)) { context in
                Text(verbatim: meta(now: context.date))
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Opens the Twitch channel."))
        .accessibilityIdentifier("live.twitch.watch.channel")
        Spacer(minLength: 8)
        if let login = video.twitchOwnerLogin ?? channelLogin {
          LiveTwitchFollowButton(login: login, onLink: onLink)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var channelLogin: String? {
    guard case let .channel(login) = video.twitchLink else { return nil }
    return login
  }

  private func meta(now: Date) -> String {
    if let live = controller.stream?.twitchMedia?.live {
      var parts = [String(localized: "\(LiveTwitchFormat.count(live.viewers)) watching")]
      if let started = LiveTwitchFormat.date(live.startedAt) {
        parts.append(String(localized: "Live for \(Duration.seconds(now.timeIntervalSince(started)).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))"))
      }
      if let game = live.game?.name { parts.append(game) }
      return parts.joined(separator: " · ")
    }
    let views = controller.stream?.viewCount ?? video.viewCount
    return views > 0 ? String(localized: "\(LiveTwitchFormat.count(Int(views))) views") : ""
  }
}
