import SwiftUI

// The title and its live figures, then the channel with the follow button. The buttons keep their one-line labels and
// the channel name gives way; at accessibility text sizes the buttons move under the channel instead.
struct LiveTwitchWatchHeader: View {
  @ObservedObject var controller: LivePlayerController
  let video: LiveVideoItem
  let dependencies: AppDependencies
  var offersQueue = false
  let onChannel: () -> Void
  let onLink: (() -> Void)?
  @StateObject private var follow = LiveTwitchFollowModel()
  @Environment(\.liveTwitchAccount) private var account
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(verbatim: controller.stream?.title ?? video.title)
          .font(.headline)
          .lineLimit(2)
          .accessibilityAddTraits(.isHeader)
        TimelineView(.periodic(from: .now, by: 60)) { context in
          LiveTwitchWatchFigures(controller: controller, video: video, now: context.date)
        }
      }
      // The chat below takes the remaining height; the header keeps its own instead of truncating to one line.
      .fixedSize(horizontal: false, vertical: true)
      if dynamicTypeSize.isAccessibilitySize {
        VStack(alignment: .leading, spacing: 10) {
          channel
          actions
        }
      } else {
        HStack(spacing: 12) {
          channel
          Spacer(minLength: 0)
          actions
        }
      }
      if follow.failed {
        Text("Twitch refused the follow.").font(.caption).foregroundStyle(.red)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .task(id: login) {
      if let login, let account { await follow.load(login: login, account: account) }
    }
  }

  private var channel: some View {
    Button(action: onChannel) {
      HStack(spacing: 10) {
        LiveTwitchAvatar(url: controller.stream?.uploaderAvatarURL ?? video.uploaderAvatarURL, size: 40)
        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: controller.stream?.uploaderName ?? video.uploaderName)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
          if let subscription = follow.subscription {
            Label { Text(verbatim: LiveTwitchChatText.subscriptionLength(subscription)) } icon: { Image(systemName: "star.fill") }
              .font(.caption.weight(.semibold))
              .foregroundStyle(.purple)
              .lineLimit(1)
              .accessibilityElement(children: .ignore)
              .accessibilityLabel(Text(verbatim: subscriptionDescription(subscription)))
          }
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityHint(Text("Opens the Twitch channel."))
    .accessibilityIdentifier("live.twitch.watch.channel")
  }

  private var actions: some View {
    HStack(spacing: 8) {
      if let login {
        LiveTwitchFollowButton(model: follow, login: login, onLink: onLink)
      }
      LiveTwitchWatchMoreMenu(
        video: video, dependencies: dependencies, isLive: controller.stream?.isLive == true, offersQueue: offersQueue
      )
    }
    .fixedSize()
  }

  private var login: String? {
    if let owner = video.twitchOwnerLogin { return owner }
    guard case let .channel(login) = video.twitchLink else { return nil }
    return login
  }

  private func subscriptionDescription(_ subscription: LiveTwitchSubscription) -> String {
    ([LiveTwitchChatText.subscription(subscription)] + LiveTwitchChatText.subscriptionDetails(subscription))
      .joined(separator: ", ")
  }
}

// Under the title: the live badge and its audience, or the views of a recording or a clip.
struct LiveTwitchWatchFigures: View {
  @ObservedObject var controller: LivePlayerController
  let video: LiveVideoItem
  let now: Date

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      if controller.stream?.isLive == true {
        Text("LIVE")
          .font(.caption2.weight(.heavy))
          .foregroundStyle(.white)
          .padding(.horizontal, 5)
          .padding(.vertical, 1)
          .background(Color.red, in: RoundedRectangle(cornerRadius: 4))
          .fixedSize()
          .accessibilityLabel(Text("Live"))
      }
      Text(verbatim: parts.joined(separator: " · "))
        .lineLimit(2)
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }

  private var parts: [String] {
    if let live = controller.stream?.twitchMedia?.live {
      var parts = [String(localized: "\(LiveTwitchFormat.count(live.viewers)) watching")]
      if let started = LiveTwitchFormat.date(live.startedAt) {
        let elapsed = Duration.seconds(now.timeIntervalSince(started))
        parts.append(String(localized: "Live for \(elapsed.formatted(.units(allowed: [.hours, .minutes], width: .narrow)))"))
      }
      if let game = live.game?.name { parts.append(game) }
      return parts
    }
    let views = controller.stream?.viewCount ?? video.viewCount
    return views > 0 ? [String(localized: "\(LiveTwitchFormat.count(Int(views))) views")] : []
  }
}
