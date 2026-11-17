import SwiftUI

struct LiveTwitchSearchResults: View {
  let query: String
  @State private var kind = LiveTwitchSearchKind.channels
  @StateObject private var channels: LiveTwitchPagedList<LiveTwitchChannel>
  @StateObject private var games: LiveTwitchPagedList<LiveTwitchGame>
  @StateObject private var streams: LiveTwitchPagedList<LiveTwitchStream>

  init(service: LiveTwitchServiceProtocol, query: String) {
    self.query = query
    _channels = StateObject(wrappedValue: LiveTwitchPagedList { try await service.searchChannels(query, after: $0) })
    _games = StateObject(wrappedValue: LiveTwitchPagedList { try await service.searchGames(query, after: $0) })
    _streams = StateObject(wrappedValue: LiveTwitchPagedList { try await service.searchStreams(query, after: $0) })
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Twitch results for “\(query)”")
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
      Picker("Result type", selection: $kind) {
        Text("Channels").tag(LiveTwitchSearchKind.channels)
        Text("Categories").tag(LiveTwitchSearchKind.games)
        Text("Lives").tag(LiveTwitchSearchKind.streams)
      }
      .pickerStyle(.segmented)
      .accessibilityIdentifier("live.twitch.search.kind")
      switch kind {
      case .channels:
        LiveTwitchPagedContent(list: channels, empty: "No results.", identifier: "live.twitch.search.channels.more") { items in
          LazyVStack(spacing: 12) {
            ForEach(items) { channel in
              NavigationLink(value: LiveTwitchRoute.channel(channel.user.login)) {
                LiveTwitchChannelRow(channel: channel)
              }
              .buttonStyle(.plain)
            }
          }
        }
        .task { await channels.prepare() }
      case .games:
        LiveTwitchPagedContent(list: games, empty: "No results.", identifier: "live.twitch.search.games.more") { items in
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 12, alignment: .top)], spacing: 16) {
            ForEach(items) { game in
              NavigationLink(value: LiveTwitchRoute.game(slug: game.slug, name: game.name)) {
                LiveTwitchGameCard(game: game)
              }
              .buttonStyle(.plain)
            }
          }
        }
        .task { await games.prepare() }
      case .streams:
        LiveTwitchStreamGrid(list: streams, empty: "No results.", identifier: "live.twitch.search.streams.more")
          .task { await streams.prepare() }
      }
    }
    .padding(.top, 8)
  }
}

struct LiveTwitchChannelRow: View {
  let channel: LiveTwitchChannel

  var body: some View {
    HStack(spacing: 12) {
      LiveTwitchAvatar(url: channel.user.avatarURL, size: 48)
      VStack(alignment: .leading, spacing: 3) {
        Text(verbatim: channel.user.name)
          .font(.subheadline.weight(.semibold))
        Text("\(LiveTwitchFormat.count(channel.followers)) followers")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
      if channel.live != nil {
        LiveTwitchBadge(text: Text("LIVE"), tint: .red)
      }
    }
    .contentShape(Rectangle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(verbatim: channel.user.name))
    .accessibilityValue(channel.live != nil ? Text("Live, \(LiveTwitchFormat.count(channel.followers)) followers") : Text("\(LiveTwitchFormat.count(channel.followers)) followers"))
    .accessibilityHint(Text("Opens the channel."))
  }
}
