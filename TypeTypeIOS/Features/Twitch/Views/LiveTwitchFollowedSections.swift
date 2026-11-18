import SwiftUI

struct LiveTwitchFollowedSections: View {
  @Environment(\.liveTwitchAccount) private var account
  @Environment(\.liveTwitchPlay) private var play
  @State private var status: LiveTwitchAccountStatus?
  @State private var live: [LiveTwitchStream] = []
  @State private var videos: [LiveTwitchVideo] = []
  @State private var channels: [LiveTwitchUser] = []

  var body: some View {
    VStack(alignment: .leading, spacing: 28) {
      if status?.linked == true {
        if !live.isEmpty {
          section("Live from channels you follow") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16, alignment: .top)], spacing: 22) {
              ForEach(live) { stream in
                Button { play(LiveTwitchPlayback.item(live: stream)) } label: { LiveTwitchStreamCard(stream: stream) }
                  .buttonStyle(.plain)
              }
            }
          }
        }
        if !videos.isEmpty {
          section("Past broadcasts from channels you follow") {
            ScrollView(.horizontal, showsIndicators: false) {
              LazyHStack(alignment: .top, spacing: 14) {
                ForEach(videos) { video in
                  Button { play(LiveTwitchPlayback.item(video: video)) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                      LiveTwitchThumbnail(url: video.previewURL) { EmptyView() } trailing: {
                        LiveTwitchBadge(text: Text(verbatim: LiveTwitchFormat.clock(TimeInterval(video.lengthSeconds))), tint: .black.opacity(0.75))
                      }
                      Text(verbatim: video.title).font(.footnote.weight(.semibold)).lineLimit(2)
                      Text(verbatim: video.owner.name).font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(width: 240, alignment: .leading)
                  }
                  .buttonStyle(.plain)
                  .accessibilityLabel(Text(verbatim: "\(video.owner.name): \(video.title)"))
                }
              }
            }
          }
        }
        if !channels.isEmpty {
          section("Channels you follow") {
            ScrollView(.horizontal, showsIndicators: false) {
              LazyHStack(spacing: 16) {
                ForEach(channels, id: \.login) { user in
                  NavigationLink(value: LiveTwitchRoute.channel(user.login)) {
                    VStack(spacing: 6) {
                      LiveTwitchAvatar(url: user.avatarURL, size: 64)
                      Text(verbatim: user.displayName).font(.caption).lineLimit(1).frame(width: 76)
                    }
                  }
                  .buttonStyle(.plain)
                  .accessibilityLabel(Text(verbatim: user.displayName))
                }
              }
            }
          }
        }
      } else if status?.linked == false {
        NavigationLink(value: LiveTwitchRoute.linkAccount) {
          Label("Link a Twitch account", systemImage: "person.crop.circle.badge.plus")
            .font(.subheadline.weight(.semibold))
        }
        .accessibilityIdentifier("live.twitch.link-account")
      }
    }
    .task { await load() }
  }

  private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title).liveSectionHeader()
      content()
    }
  }

  private func load() async {
    guard let account, let current = try? await account.account() else { return }
    status = current
    guard current.linked else { return }
    async let followedLive = try? account.followedLive(after: nil)
    async let followedVideos = try? account.followedVideos(after: nil)
    async let followedChannels = try? account.followedChannels(after: nil)
    live = await followedLive?.items ?? []
    videos = await followedVideos?.items ?? []
    channels = await followedChannels?.items ?? []
  }
}
