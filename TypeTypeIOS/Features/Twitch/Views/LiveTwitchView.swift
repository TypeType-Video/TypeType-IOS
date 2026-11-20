import SwiftUI

struct LiveTwitchView: View {
  let service: LiveTwitchServiceProtocol
  @StateObject private var games: LiveTwitchPagedList<LiveTwitchGame>
  @StateObject private var streams: LiveTwitchPagedList<LiveTwitchStream>
  @State private var path = NavigationPath()
  @State private var query = ""
  @State private var submittedQuery = ""

  init(service: LiveTwitchServiceProtocol) {
    self.service = service
    _games = StateObject(wrappedValue: LiveTwitchPagedList { try await service.games(after: $0) })
    _streams = StateObject(wrappedValue: LiveTwitchPagedList { try await service.streams(after: $0) })
  }

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        Group {
          if submittedQuery.isEmpty {
            home
          } else {
            LiveTwitchSearchResults(service: service, query: submittedQuery)
              .id(submittedQuery)
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
      }
      .background(LiveThemeBackground().ignoresSafeArea())
      .navigationTitle("Live")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $query, prompt: Text("Search Twitch"))
      .onSubmit(of: .search) {
        submittedQuery = String(query.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
      }
      .onChange(of: query) { _, text in
        if text.isEmpty { submittedQuery = "" }
      }
      .refreshable {
        async let categories: Void = games.reload()
        async let lives: Void = streams.reload()
        _ = await (categories, lives)
      }
      .navigationDestination(for: LiveTwitchRoute.self) { route in
        LiveTwitchDestination(route: route, service: service)
      }
      .task {
        async let categories: Void = games.prepare()
        async let lives: Void = streams.prepare()
        _ = await (categories, lives)
      }
      .accessibilityIdentifier("live.twitch.screen")
    }
  }

  private var home: some View {
    VStack(alignment: .leading, spacing: 28) {
      LiveTwitchFollowedSections()
      if !games.items.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          Text("Categories").liveSectionHeader()
          ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
              ForEach(games.items.prefix(20)) { game in
                NavigationLink(value: LiveTwitchRoute.game(slug: game.slug, name: game.name)) {
                  LiveTwitchGameCard(game: game)
                }
                .buttonStyle(.plain)
              }
            }
          }
        }
      }
      VStack(alignment: .leading, spacing: 12) {
        Text("Popular lives").liveSectionHeader()
        LiveTwitchStreamGrid(list: streams, empty: "No live right now.", identifier: "live.twitch.streams.more")
      }
    }
    .padding(.top, 8)
  }
}

struct LiveTwitchDestination: View {
  let route: LiveTwitchRoute
  let service: LiveTwitchServiceProtocol
  @Environment(\.liveTwitchAccount) private var account

  var body: some View {
    switch route {
    case let .channel(login):
      LiveTwitchChannelView(login: login, service: service)
    case let .game(slug, name):
      LiveTwitchStreamsView(title: Text(verbatim: name), identifier: "live.twitch.game.more") {
        try await service.gameStreams(slug: slug, after: $0).streams
      }
    case let .tag(tag):
      LiveTwitchStreamsView(title: Text("\(tag) lives"), identifier: "live.twitch.tag.more") {
        try await service.tagStreams(tag: tag, after: $0)
      }
    case .linkAccount:
      if let account { LiveTwitchLinkPage(service: account) }
    }
  }
}

struct LiveTwitchStreamsView: View {
  let title: Text
  let identifier: String
  @StateObject private var list: LiveTwitchPagedList<LiveTwitchStream>

  init(title: Text, identifier: String, load: @escaping (String?) async throws -> LiveTwitchPage<LiveTwitchStream>) {
    self.title = title
    self.identifier = identifier
    _list = StateObject(wrappedValue: LiveTwitchPagedList(load: load))
  }

  var body: some View {
    ScrollView {
      LiveTwitchStreamGrid(list: list, empty: "No live right now.", identifier: identifier)
        .padding()
    }
    .background(LiveThemeBackground().ignoresSafeArea())
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable { await list.reload() }
    .task { await list.prepare() }
  }
}
