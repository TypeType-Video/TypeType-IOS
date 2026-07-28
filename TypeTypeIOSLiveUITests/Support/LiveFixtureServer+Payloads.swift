import Foundation

extension LiveFixtureServer {
  static let instanceJSON = """
    {
      "name":"TypeType Fixture",
      "tagline":"Local integration test",
      "version":"fixture",
      "apiVersion":1,
      "registrationAllowed":true,
      "guestAllowed":true,
      "supportedServices":[0,5],
      "logoUrl":null,
      "bannerUrl":null,
      "localLoginEnabled":true,
      "oidcEnabled":false,
      "oidcProviderName":null,
      "oidcAutoRedirect":false,
      "youtubeRemoteLoginEnabled":false,
      "youtubeRemoteLoginReady":false,
      "youtubeRemoteLoginUnavailableReason":null
    }
    """

  static let searchFiltersJSON = """
    {
      "contentFilters":[
        {"value":"|0|all","label":"all"},
        {"value":"|1|videos","label":"videos"},
        {"value":"|2|channels","label":"channels"}
      ],
      "sortFilters":[]
    }
    """

  static let channelResultJSON = """
    {
      "id":"fixture-channel",
      "name":"Blender Fixture",
      "url":"https://www.youtube.com/channel/UCfixture",
      "thumbnailUrl":"https://example.test/channel.jpg",
      "description":"A channel returned by the backend fixture.",
      "subscriberCount":1200000,
      "streamCount":120,
      "isVerified":true
    }
    """

  static let playlistJSON = """
    {
      "id":"fixture-playlist",
      "title":"Backend playlist",
      "url":"https://www.youtube.com/playlist?list=fixture",
      "thumbnailUrl":"https://example.test/playlist.jpg",
      "uploaderName":"Blender Fixture",
      "streamCount":12,
      "playlistType":"normal"
    }
    """

  static let channelPlaylistsJSON = """
    {"playlists":[\(playlistJSON)],"nextpage":null}
    """

  static let podcastsJSON = """
    {
      "channelName":"Blender Fixture",
      "channelUrl":"https://www.youtube.com/channel/UCfixture",
      "podcasts":[{
        "id":"fixture-podcast",
        "title":"Backend podcast",
        "url":"https://www.youtube.com/playlist?list=podcast",
        "thumbnailUrl":"https://example.test/podcast.jpg",
        "uploaderName":"Blender Fixture",
        "streamCount":6,
        "playlistType":"podcast"
      }],
      "episodes":[],
      "nextpage":null
    }
    """

  static let subscriptionJSON = """
    {
      "channelUrl":"https://www.youtube.com/channel/UCfixture",
      "name":"Blender Fixture",
      "avatarUrl":"https://example.test/channel.jpg",
      "subscribedAt":1785063770906
    }
    """

  static func downloadJob(
    status: String,
    stage: String,
    mode: String = "video"
  ) -> String {
    let completed = status == "done"
    let audioOnly = mode == "audio"
    return """
    {
      "id":"fixture-download",
      "url":"https://www.youtube.com/watch?v=video-1",
      "status":"\(status)",
      "title":"Backend recommendation",
      "resolved":{
        "videoItag":\(audioOnly ? "null" : #""137""#),
        "audioItag":"140",
        "height":\(audioOnly ? "null" : "1080"),
        "fps":\(audioOnly ? "null" : "30"),
        "videoCodec":\(audioOnly ? "null" : #""avc1""#),
        "audioCodec":"mp4a",
        "container":"\(audioOnly ? "m4a" : "mp4")",
        "bitrate":null,
        "fileName":"Backend recommendation.\(audioOnly ? "m4a" : "mp4")"
      },
      "progressPercent":\(completed ? 100 : 0),
      "downloadedBytes":\(completed ? 21 : 0),
      "totalBytes":21,
      "speedBytesPerSecond":null,
      "etaSeconds":null,
      "stage":"\(stage)",
      "queuedAt":null,
      "startedAt":null,
      "finishedAt":null,
      "queueWaitMs":null,
      "runTimeMs":null,
      "errorCode":null,
      "error":null
    }
    """
  }

  static let nicoStreamJSON = """
    {
      "id":"https://www.nicovideo.jp/watch/sm9",
      "title":"NicoNico video",
      "uploaderName":"TypeType Channel",
      "uploaderUrl":"https://www.nicovideo.jp/user/fixture",
      "uploaderAvatarUrl":"https://example.test/avatar.jpg",
      "thumbnailUrl":"https://example.test/nico.jpg",
      "description":"A backend fixture video.",
      "duration":10,
      "viewCount":12345,
      "likeCount":128000,
      "dislikeCount":1200,
      "startPosition":0,
      "hlsUrl":"https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4",
      "videoStreams":[],
      "audioStreams":[],
      "videoOnlyStreams":[],
      "subtitles":[],
      "streamSegments":[],
      "sponsorBlockSegments":[{
        "startTime":0,
        "endTime":10000,
        "category":"exclusive_access",
        "action":"skip"
      }],
      "relatedStreams":[],
      "isLive":false,
      "isPostLive":false,
      "isLiveContent":false
    }
    """

  static func video(
    id: String,
    title: String,
    url: String? = nil,
    isShort: Bool = false
  ) -> String {
    """
    {
      "id":"\(id)",
      "title":"\(title)",
      "url":"\(url ?? "https://www.youtube.com/watch?v=\(id)")",
      "thumbnailUrl":"https://example.test/\(id).jpg",
      "uploaderName":"TypeType Channel",
      "uploaderUrl":"https://example.test/channel",
      "uploaderAvatarUrl":"https://example.test/avatar.jpg",
      "duration":596,
      "viewCount":12345,
      "uploadDate":"2026-07-26",
      "uploaded":-1,
      "streamType":"VIDEO_STREAM",
      "isShortFormContent":\(isShort),
      "uploaderVerified":true,
      "shortDescription":"A backend fixture video.",
      "publishedAt":1785063770906,
      "isLive":false,
      "isPostLive":false,
      "isLiveContent":false,
      "requiresMembership":false
    }
    """
  }

  static func page(
    items: [String],
    cursor: String?,
    hasMore: Bool
  ) -> String {
    let cursorJSON = cursor.map { "\"\($0)\"" } ?? "null"
    return """
    {
      "items":[\(items.joined(separator: ","))],
      "nextCursor":\(cursorJSON),
      "hasMore":\(hasMore)
    }
    """
  }

  static func searchPage(
    items: [String],
    channels: [String],
    playlists: [String],
    nextPage: String?
  ) -> String {
    let nextJSON = nextPage.map { "\"\($0)\"" } ?? "null"
    return """
    {
      "items":[\(items.joined(separator: ","))],
      "channels":[\(channels.joined(separator: ","))],
      "playlists":[\(playlists.joined(separator: ","))],
      "nextpage":\(nextJSON),
      "searchSuggestion":null,
      "isCorrectedSearch":false
    }
    """
  }

  static func channelJSON(
    videos: [String],
    nextPage: String?
  ) -> String {
    let nextJSON = nextPage.map { "\"\($0)\"" } ?? "null"
    return """
    {
      "name":"Blender Fixture",
      "description":"A real HTTP fixture channel.",
      "avatarUrl":"https://example.test/channel.jpg",
      "bannerUrl":"https://example.test/banner.jpg",
      "subscriberCount":1200000,
      "isVerified":true,
      "videos":[\(videos.joined(separator: ","))],
      "nextpage":\(nextJSON)
    }
    """
  }

  static func json(_ body: String) -> Data {
    http(
      status: "200 OK",
      body: body,
      contentType: "application/json"
    )
  }

  static func http(
    status: String,
    body: String,
    contentType: String = "application/json"
  ) -> Data {
    http(
      status: status,
      body: Data(body.utf8),
      contentType: contentType
    )
  }

  static func http(
    status: String,
    body: Data,
    contentType: String
  ) -> Data {
    let headers = [
      "HTTP/1.0 \(status)",
      "Content-Type: \(contentType)",
      "Content-Length: \(body.count)",
      "Connection: close",
      "",
      "",
    ].joined(separator: "\r\n")
    var response = Data(headers.utf8)
    response.append(body)
    return response
  }
}

enum LiveFixtureServerError: Error {
  case startFailed
  case invalidURL
}
