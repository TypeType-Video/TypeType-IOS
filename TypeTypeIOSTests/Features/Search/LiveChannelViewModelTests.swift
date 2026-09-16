import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveChannelViewModelTests: XCTestCase {
  func testInitialLoadTreatsShortsAsRegularVideos() async {
    let video = LiveVideoItemFixture.make(
      id: "video",
      url: "https://youtube.test/video"
    )
    let channel = ChannelServiceStub(
      channelPages: [
        Self.page(videos: [
          video,
          LiveVideoItemFixture.make(id: "short", isShort: true),
        ]),
      ],
      podcastPages: [
        LivePodcastPage(
          channelName: "Blender",
          channelURL: Self.url,
          podcasts: [Self.podcast],
          episodes: [],
          nextPage: nil
        ),
      ]
    )
    let subscriptions = SubscriptionsServiceStub(
      values: [
        LiveSubscription(
          channelURL: Self.url,
          name: "Blender",
          avatarURL: "",
          subscribedAt: 1
        ),
      ]
    )
    let viewModel = makeViewModel(
      channel: channel,
      subscriptions: subscriptions
    )

    await viewModel.loadIfNeeded()

    XCTAssertEqual(viewModel.state, .loaded)
    XCTAssertEqual(viewModel.channel?.name, "Blender")
    XCTAssertEqual(viewModel.videos.map(\.id), ["video", "short"])
    XCTAssertEqual(viewModel.podcasts.map(\.title), ["Open Movies"])
    XCTAssertTrue(viewModel.isSubscribed)
  }

  func testPlaylistTabLoadsAndPaginatesOpaquePages() async {
    let channel = ChannelServiceStub(
      channelPages: [],
      playlistPages: [
        LiveChannelPlaylistsPage(
          playlists: [Self.playlist],
          nextPage: "opaque"
        ),
        LiveChannelPlaylistsPage(
          playlists: [
            Self.playlist,
            LivePlaylistResult(
              id: "two",
              title: "Conference",
              url: "https://youtube.test/playlist/two",
              thumbnailURL: "",
              uploaderName: "Blender",
              streamCount: 4,
              playlistType: "normal"
            ),
          ],
          nextPage: nil
        ),
      ]
    )
    let viewModel = makeViewModel(
      channel: channel,
      subscriptions: SubscriptionsServiceStub(values: [])
    )

    await viewModel.selectTab(.playlists)
    await viewModel.loadMore()

    XCTAssertEqual(
      viewModel.playlists.map(\.title),
      ["Open Movies", "Conference"]
    )
    XCTAssertEqual(channel.playlistCalls.last?.nextPage, "opaque")
    XCTAssertFalse(viewModel.canLoadMore)
  }

  func testSubscriptionMutationIsSentToServer() async {
    let channel = ChannelServiceStub(
      channelPages: [Self.page(videos: [])]
    )
    let subscriptions = SubscriptionsServiceStub(values: [])
    let viewModel = makeViewModel(
      channel: channel,
      subscriptions: subscriptions
    )

    await viewModel.loadIfNeeded()
    await viewModel.toggleSubscription()
    await viewModel.toggleSubscription()

    XCTAssertEqual(subscriptions.subscribedURLs, [Self.url])
    XCTAssertEqual(subscriptions.unsubscribedURLs, [Self.url])
    XCTAssertFalse(viewModel.isSubscribed)
  }

  func testChannelNotificationPreferenceLoadsAndToggles() async {
    let channel = ChannelServiceStub(
      channelPages: [Self.page(videos: [])]
    )
    let push = PushNotificationsServiceStub(
      preferences: [
        LiveChannelNotificationPreference(
          channelURL: Self.url,
          enabled: false,
          updatedAt: 20
        )
      ]
    )
    let viewModel = makeViewModel(
      channel: channel,
      subscriptions: SubscriptionsServiceStub(
        values: [
          LiveSubscription(
            channelURL: Self.url,
            name: "Blender",
            avatarURL: "",
            subscribedAt: 1
          )
        ]
      ),
      push: push,
      pushEnabled: true
    )

    await viewModel.loadIfNeeded()

    XCTAssertTrue(viewModel.isNotificationsAvailable)
    XCTAssertFalse(viewModel.isNotificationsEnabled)

    await viewModel.toggleNotifications()

    XCTAssertTrue(viewModel.isNotificationsEnabled)
    XCTAssertEqual(push.updated?.enabled, true)
    XCTAssertEqual(push.updated?.channelURL, Self.url)
  }

  private func makeViewModel(
    channel: ChannelServiceStub,
    subscriptions: SubscriptionsServiceStub,
    push: PushNotificationsServiceStub? = nil,
    pushEnabled: Bool = false
  ) -> LiveChannelViewModel {
    LiveChannelViewModel(
      channelURL: Self.url,
      channelService: channel,
      subscriptionsService: subscriptions,
      pushNotificationsService: push,
      pushNotificationsEnabled: pushEnabled
    )
  }

  private static func page(
    videos: [LiveVideoItem]
  ) -> LiveChannelPage {
    LiveChannelPage(
      name: "Blender",
      description: "Official channel",
      avatarURL: "",
      bannerURL: "",
      subscriberCount: 1_200,
      isVerified: true,
      videos: videos,
      nextPage: nil
    )
  }

  private static let url =
    "https://www.youtube.com/channel/UC123"

  private static let playlist = LivePlaylistResult(
    id: "one",
    title: "Open Movies",
    url: "https://youtube.test/playlist/one",
    thumbnailURL: "",
    uploaderName: "Blender",
    streamCount: 12,
    playlistType: "normal"
  )

  private static let podcast = LivePodcastItem(
    id: "podcast",
    title: "Open Movies",
    url: "https://youtube.test/podcast",
    thumbnailURL: "",
    uploaderName: "Blender",
    streamCount: 5,
    playlistType: "podcast"
  )
}

private final class ChannelServiceStub: LiveChannelServiceProtocol {
  struct Call {
    let nextPage: String?
  }

  private let lock = NSLock()
  private var channelPages: [LiveChannelPage]
  private var playlistPages: [LiveChannelPlaylistsPage]
  private var podcastPages: [LivePodcastPage]
  private var recordedPlaylistCalls: [Call] = []

  init(
    channelPages: [LiveChannelPage],
    playlistPages: [LiveChannelPlaylistsPage] = [],
    podcastPages: [LivePodcastPage] = []
  ) {
    self.channelPages = channelPages
    self.playlistPages = playlistPages
    self.podcastPages = podcastPages
  }

  var playlistCalls: [Call] {
    lock.withLock { recordedPlaylistCalls }
  }

  func channel(
    url: String,
    nextPage: String?,
    sort: LiveChannelSort
  ) async throws -> LiveChannelPage {
    try lock.withLock {
      guard !channelPages.isEmpty else {
        throw ChannelViewModelTestError.unavailable
      }
      return channelPages.removeFirst()
    }
  }

  func playlists(
    url: String,
    nextPage: String?
  ) async throws -> LiveChannelPlaylistsPage {
    try lock.withLock {
      recordedPlaylistCalls.append(Call(nextPage: nextPage))
      guard !playlistPages.isEmpty else {
        throw ChannelViewModelTestError.unavailable
      }
      return playlistPages.removeFirst()
    }
  }

  func podcasts(
    url: String,
    nextPage: String?
  ) async throws -> LivePodcastPage {
    try lock.withLock {
      guard !podcastPages.isEmpty else {
        throw ChannelViewModelTestError.unavailable
      }
      return podcastPages.removeFirst()
    }
  }

  func podcastEpisodes(
    url: String,
    nextPage: String?
  ) async throws -> LivePodcastEpisodesPage {
    throw ChannelViewModelTestError.unavailable
  }
}

private final class SubscriptionsServiceStub:
  LiveSubscriptionsServiceProtocol {
  private let lock = NSLock()
  private var values: [LiveSubscription]
  private var subscribed: [String] = []
  private var unsubscribed: [String] = []

  init(values: [LiveSubscription]) {
    self.values = values
  }

  var subscribedURLs: [String] {
    lock.withLock { subscribed }
  }

  var unsubscribedURLs: [String] {
    lock.withLock { unsubscribed }
  }

  func subscriptions() async throws -> [LiveSubscription] {
    lock.withLock { values }
  }

  func feed(
    nextPage: String?
  ) async throws -> LiveSubscriptionFeedPage {
    LiveSubscriptionFeedPage(
      videos: [],
      nextPage: nil,
      generation: nil,
      generatedAt: nil,
      refreshing: false
    )
  }

  func subscribe(
    channelURL: String,
    name: String,
    avatarURL: String
  ) async throws -> LiveSubscription {
    lock.withLock {
      subscribed.append(channelURL)
      let value = LiveSubscription(
        channelURL: channelURL,
        name: name,
        avatarURL: avatarURL,
        subscribedAt: 2
      )
      values.append(value)
      return value
    }
  }

  func unsubscribe(channelURL: String) async throws {
    lock.withLock {
      unsubscribed.append(channelURL)
      values.removeAll { $0.channelURL == channelURL }
    }
  }
}

private final class PushNotificationsServiceStub:
  LivePushNotificationsServiceProtocol {
  private let lock = NSLock()
  private var preferences: [LiveChannelNotificationPreference]
  private(set) var updated: LiveChannelNotificationPreference?

  init(preferences: [LiveChannelNotificationPreference]) {
    self.preferences = preferences
  }

  func channelPreferences() async throws -> [
    LiveChannelNotificationPreference
  ] {
    lock.withLock { preferences }
  }

  func setChannelPreference(
    channelURL: String,
    enabled: Bool
  ) async throws -> LiveChannelNotificationPreference {
    lock.withLock {
      let value = LiveChannelNotificationPreference(
        channelURL: channelURL,
        enabled: enabled,
        updatedAt: 30
      )
      if let index = preferences.firstIndex(where: {
        $0.channelURL == channelURL
      }) {
        preferences[index] = value
      } else {
        preferences.append(value)
      }
      updated = value
      return value
    }
  }
}

private enum ChannelViewModelTestError: Error {
  case unavailable
}
