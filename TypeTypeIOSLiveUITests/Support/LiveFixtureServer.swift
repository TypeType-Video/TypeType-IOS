import Foundation
import Network

final class LiveFixtureServer {
  private let queue = DispatchQueue(
    label: "LiveFixtureServer"
  )
  private let prefersNicoRecommendation: Bool
  private var listener: NWListener?
  private var downloadMode = "video"

  init(prefersNicoRecommendation: Bool = false) {
    self.prefersNicoRecommendation = prefersNicoRecommendation
  }

  func start() throws -> URL {
    let parameters = NWParameters.tcp
    parameters.requiredLocalEndpoint = .hostPort(
      host: "127.0.0.1",
      port: .any
    )
    let listener = try NWListener(using: parameters)
    self.listener = listener
    let ready = DispatchSemaphore(value: 0)
    listener.stateUpdateHandler = { state in
      if case .ready = state {
        ready.signal()
      }
    }
    listener.newConnectionHandler = { [weak self] connection in
      self?.handle(connection)
    }
    listener.start(queue: queue)
    guard ready.wait(timeout: .now() + 3) == .success,
      let port = listener.port
    else {
      throw LiveFixtureServerError.startFailed
    }
    guard let url = URL(
      string: "http://127.0.0.1:\(port.rawValue)"
    ) else {
      throw LiveFixtureServerError.invalidURL
    }
    return url
  }

  func stop() {
    listener?.cancel()
    listener = nil
  }

  private func handle(_ connection: NWConnection) {
    connection.start(queue: queue)
    connection.receive(
      minimumIncompleteLength: 1,
      maximumLength: 65_536
    ) { data, _, _, _ in
      let request = data.flatMap {
        String(data: $0, encoding: .utf8)
      } ?? ""
      if request.contains("POST /api/downloader/jobs "),
        request.contains(#""mode":"audio""#) {
        self.downloadMode = "audio"
      } else if request.contains("POST /api/downloader/jobs ") {
        self.downloadMode = "video"
      }
      let response = Self.response(
        for: request,
        prefersNicoRecommendation: self.prefersNicoRecommendation,
        downloadMode: self.downloadMode
      )
      connection.send(
        content: response,
        contentContext: .finalMessage,
        isComplete: true,
        completion: .contentProcessed { _ in
          connection.cancel()
        }
      )
    }
  }

  private static func response(
    for request: String,
    prefersNicoRecommendation: Bool,
    downloadMode: String
  ) -> Data {
    let firstLine = request.split(separator: "\r\n").first
      .map(String.init) ?? ""
    let parts = firstLine.split(separator: " ")
    let method = parts.first.map(String.init) ?? "GET"
    let target = parts.dropFirst().first
      .map(String.init) ?? "/"
    let components = URLComponents(string: target)
    let path = components?.path ?? target
    let query = components?.queryItems?.reduce(
      into: [String: String]()
    ) {
      $0[$1.name] = $1.value
    } ?? [:]

    switch path {
    case "/api/instance":
      return json(instanceJSON)
    case "/api/auth/register/status":
      return json(
        """
        {"allowRegistration":true,"bootstrapAvailable":false,\
        "localLoginEnabled":true}
        """
      )
    case "/api/auth/oidc/status":
      return json(
        """
        {"enabled":false,"providerName":null,\
        "localLoginEnabled":true,"autoRedirect":false}
        """
      )
    case "/api/auth/guest":
      return json(#"{"accessToken":"fixture-token"}"#)
    case "/api/auth/login":
      return json(#"{"accessToken":"fixture-account-token"}"#)
    case "/api/auth/me":
      return json(
        """
        {"id":"fixture-user","role":"user",\
        "publicUsername":"Fixture","bio":null,"avatarUrl":null,\
        "avatarType":null,"avatarCode":null}
        """
      )
    case "/api/auth/logout":
      return http(status: "204 No Content", body: "")
    case "/api/recommendations/home":
      return json(
        recommendations(
          query: query,
          prefersNicoRecommendation: prefersNicoRecommendation
        )
      )
    case "/api/settings":
      return json(
        settingsJSON(
          defaultService: request.contains(
            #""defaultService":5"#
          ) ? 5 : 0
        )
      )
    case "/api/history":
      return json("[]")
    case "/api/favorites",
      "/api/watch-later",
      "/api/playlists",
      "/api/saved-playlists":
      return json("[]")
    case "/api/profile/public/Fixture":
      return json(
        """
        {"publicUsername":"Fixture","bio":"Fixture profile",\
        "avatarUrl":null,"avatarType":null,"avatarCode":null}
        """
      )
    case "/api/profile/account":
      return json(
        """
        {"email":"fixture@example.test","name":"Fixture",\
        "managedByOidc":false}
        """
      )
    case "/api/notifications/unread-count":
      return json(#"{"unreadCount":2}"#)
    case "/api/notifications":
      return json(
        #"{"items":[],"unreadCount":2,"nextpage":null}"#
      )
    case "/api/notifications/read-all":
      return json(
        #"{"readAt":1785063770906,"unreadCount":0}"#
      )
    case "/api/sessions/activity":
      return http(status: "204 No Content", body: "")
    case "/api/search/filters":
      return json(searchFiltersJSON)
    case "/api/trending":
      return json(
        "[\(video(id: "trending-1", title: "Backend trending"))]"
      )
    case "/api/suggestions":
      return json(
        #"["Backend search","Backend search tutorial"]"#
      )
    case "/api/search":
      return json(search(query: query))
    case "/api/search-history":
      if method == "DELETE" {
        return http(status: "204 No Content", body: "")
      }
      if method == "POST" {
        return json(
          """
          {"id":"fixture-history","term":"Backend search",\
          "searchedAt":1785063770906}
          """
        )
      }
      return json("[]")
    case "/api/downloader/jobs":
      return json(
        downloadJob(
          status: "queued",
          stage: "queued",
          mode: downloadMode
        )
      )
    case "/api/downloader/jobs/fixture-download":
      if method == "DELETE" {
        return http(status: "204 No Content", body: "")
      }
      return json(
        downloadJob(
          status: "done",
          stage: "done",
          mode: downloadMode
        )
      )
    case "/api/downloader/jobs/fixture-download/cancel":
      return json(
        downloadJob(
          status: "cancelled",
          stage: "cancelled",
          mode: downloadMode
        )
      )
    case "/api/downloader/jobs/fixture-download/artifact":
      guard let media = fixtureDownloadMedia else {
        return http(
          status: "500 Internal Server Error",
          body: #"{"error":"Fixture media is missing"}"#
        )
      }
      return http(
        status: "200 OK",
        body: media,
        contentType: downloadMode == "audio"
          ? "audio/mp4"
          : "video/mp4"
      )
    case "/api/channel/page":
      return json(channelPage(request: request))
    case "/api/channel/playlists":
      return json(channelPlaylistsJSON)
    case "/api/podcasts":
      return json(podcastsJSON)
    case "/api/podcasts/episodes":
      return json(
        """
        {"podcast":{"name":"Fixture podcast","url":"https://youtube.test/playlist",\
        "thumbnailUrl":"","uploaderName":"Fixture channel","uploaderUrl":"https://youtube.test/channel",\
        "streamCount":1},"episodes":[\(video(id: "episode-1", title: "Podcast episode"))],\
        "nextpage":null}
        """
      )
    case "/api/comments":
      return json(
        """
        {"comments":[{"id":"comment-1","text":"Fixture comment",\
        "author":"Fixture viewer","authorUrl":"https://youtube.test/viewer",\
        "authorAvatarUrl":"","likeCount":3,"textualLikeCount":"3",\
        "publishedTime":"now","publishedAt":1785063770906,\
        "isHeartedByUploader":false,"isPinned":false,\
        "uploaderVerified":false,"replyCount":0,"repliesPage":null}],\
        "nextpage":null,"commentsDisabled":false}
        """
      )
    case "/api/streams/niconico":
      return json(nicoStreamJSON)
    case "/api/bullet-comments":
      return json(
        """
        {"comments":[{"text":"Fixture danmaku","argbColor":-1,\
        "position":"TOP","relativeFontSize":1.0,"durationMs":0,\
        "isLive":false}],"nextpage":null}
        """
      )
    case "/api/subscriptions":
      if method == "POST" {
        return json(subscriptionJSON)
      }
      if method == "DELETE" {
        return http(status: "204 No Content", body: "")
      }
      return json("[]")
    case "/api/subscriptions/feed":
      return json(
        """
        {"videos":[],"nextpage":null,"generation":1,\
        "generatedAt":1785063770906,"refreshing":false}
        """
      )
    default:
      return http(
        status: "404 Not Found",
        body: #"{"error":"Not found"}"#
      )
    }
  }

  private static var fixtureDownloadMedia: Data? {
    let repository = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    let mediaURL = repository
      .appendingPathComponent("TypeTypeIOS")
      .appendingPathComponent("Resources")
      .appendingPathComponent("Media")
      .appendingPathComponent("BigBuckBunnyDemo.mp4")
    return try? Data(contentsOf: mediaURL)
  }

  private static func settingsJSON(
    defaultService: Int
  ) -> String {
    """
    {"defaultService":\(defaultService),"defaultQuality":"1080p",\
    "defaultLandingPage":"home","autoplay":true,\
    "skipPlaylistAutoplayScreen":false,"volume":1.0,"muted":false,\
    "subtitlesEnabled":false,"defaultSubtitleLanguage":"",\
    "defaultAudioLanguage":"","captionStyles":{"fontFamily":"",\
    "fontSize":"","textColor":"","textOpacity":"","textShadow":"",\
    "textBg":"","textBgOpacity":"","displayBg":"","displayBgOpacity":""},\
    "preferOriginalLanguage":false,"enableHighQualityPlayback":false,\
    "sponsorBlockMode":"auto_skip","sponsorBlockCategoryActions":{},\
    "sponsorBlockMinimumDuration":0,"sponsorBlockShowCurrentSegment":true,\
    "sponsorBlockShowChapters":false,"sponsorBlockShowFullVideoLabels":true,\
    "sponsorBlockManualSkipOnFullVideo":true,\
    "sponsorBlockSkipNonMusicOnlyOnMusicVideos":false,\
    "sponsorBlockMuteInsteadOfSkip":false,\
    "hideHomeRecommendations":false,"hideContinueWatching":false,\
    "hideRelatedVideos":false,"hideComments":false,"hideShorts":true,\
    "disableWatchHistory":false,"deArrowEnabled":false,\
    "deArrowTitleMode":"dearrow","deArrowThumbnailMode":"dearrow_or_random",\
    "deArrowTrustMode":"accepted","accessMode":"unrestricted"}
    """
  }

  private static func recommendations(
    query: [String: String],
    prefersNicoRecommendation: Bool
  ) -> String {
    if query["service"] == "5" {
      return page(
        items: [
          video(
            id: "bilibili-1",
            title: "BiliBili recommendation",
            url: "https://www.bilibili.com/video/BV1fixture"
          ),
        ],
        cursor: nil,
        hasMore: false
      )
    }
    if query["cursor"] == "page-2" {
      return page(
        items: [
          video(id: "video-2", title: "Loaded automatically"),
        ],
        cursor: nil,
        hasMore: false
      )
    }
    let nico = video(
      id: "nico-1",
      title: "NicoNico video",
      url: "https://www.nicovideo.jp/watch/sm9"
    )
    let regular = video(
      id: "video-1",
      title: "Backend recommendation"
    )
    let short = video(
      id: "short-1",
      title: "Short video",
      isShort: true
    )
    return page(
      items: prefersNicoRecommendation
        ? [nico, regular, short]
        : [regular, short, nico],
      cursor: "page-2",
      hasMore: true
    )
  }

  private static func search(query: [String: String]) -> String {
    if query["nextpage"] == "search-page-2" {
      return searchPage(
        items: [
          video(id: "search-video-2", title: "Search page two"),
        ],
        channels: [],
        playlists: [],
        nextPage: nil
      )
    }
    return searchPage(
      items: [
        video(id: "search-video-1", title: "Backend search result"),
        video(id: "search-short", title: "Search short video", isShort: true),
      ],
      channels: [channelResultJSON],
      playlists: [playlistJSON],
      nextPage: "search-page-2"
    )
  }

  private static func channelPage(request: String) -> String {
    if request.contains(#""nextpage":"channel-page-2""#) {
      return channelJSON(
        videos: [
          video(id: "channel-video-2", title: "Channel page two"),
        ],
        nextPage: nil
      )
    }
    return channelJSON(
      videos: [
        video(id: "channel-video-1", title: "Channel backend video"),
      ],
      nextPage: "channel-page-2"
    )
  }
}
