import Foundation

enum LiveTwitchPlayback {
  static func url(for link: LiveTwitchLink) -> String {
    switch link {
    case let .channel(login): "https://www.twitch.tv/\(login)"
    case let .video(id): "https://www.twitch.tv/videos/\(id)"
    case let .clip(slug): "https://clips.twitch.tv/\(slug)"
    }
  }

  static func item(for link: LiveTwitchLink) -> LiveVideoItem {
    item(link: link, title: "Twitch", owner: nil, thumbnail: "", duration: 0, views: 0, isLive: false)
  }

  static func item(live stream: LiveTwitchStream) -> LiveVideoItem {
    item(link: .channel(stream.user.login), title: stream.title, owner: stream.user, thumbnail: stream.previewURL,
         duration: 0, views: stream.viewers, isLive: true)
  }

  static func item(video: LiveTwitchVideo) -> LiveVideoItem {
    item(link: .video(video.id), title: video.title, owner: video.owner, thumbnail: video.previewURL,
         duration: video.lengthSeconds, views: video.views, isLive: false)
  }

  static func item(clip: LiveTwitchClip) -> LiveVideoItem {
    item(link: .clip(clip.slug), title: clip.title, owner: clip.broadcaster, thumbnail: clip.thumbnailURL,
         duration: Int(clip.durationSeconds.rounded()), views: clip.views, isLive: false)
  }

  static func stream(live: LiveTwitchLive, origin: URL?) throws -> LivePlaybackStream {
    guard let stream = live.channel.live else { throw LiveTwitchPlaybackError.offline }
    guard let url = absolute(live.hlsURL, origin: origin) else { throw LivePlaybackFailure.noPlayableSource }
    var playback = base(item(live: stream), description: live.channel.description, owner: stream.user, isLive: true,
                        category: stream.game?.name)
    playback.twitchMedia = LiveTwitchMedia(url: url, audioURL: live.audioURL.flatMap { absolute($0, origin: origin) }, live: stream)
    return playback
  }

  static func stream(video answer: LiveTwitchVideoPlayback, chapters: [LiveTwitchChapter], origin: URL?) throws -> LivePlaybackStream {
    guard let url = absolute(answer.hlsURL, origin: origin) else { throw LivePlaybackFailure.noPlayableSource }
    var playback = base(item(video: answer.video), description: "", owner: answer.video.owner, isLive: false,
                        chapters: chapters.map { LivePlaybackChapter(title: $0.title, startTimeSeconds: $0.start, channelName: nil, url: nil, previewURL: nil) })
    playback.twitchMedia = LiveTwitchMedia(url: url, audioURL: answer.audioURL.flatMap { absolute($0, origin: origin) })
    return playback
  }

  static func stream(clip answer: LiveTwitchClipPlayback, origin: URL?) throws -> LivePlaybackStream {
    let ordered = answer.qualities.sorted { (Int($0.quality) ?? 0) > (Int($1.quality) ?? 0) }
    guard let best = ordered.lazy.compactMap({ absolute($0.url, origin: origin) }).first else {
      throw LivePlaybackFailure.noPlayableSource
    }
    var playback = base(item(clip: answer.clip), description: "", owner: answer.clip.broadcaster, isLive: false)
    playback.twitchMedia = LiveTwitchMedia(url: best, audioURL: nil)
    return playback
  }

  // Twitch links are signed paths at the root of the instance, not under its API prefix.
  static func absolute(_ value: String, origin: URL?) -> URL? {
    if let url = URL(string: value), url.scheme != nil { return url }
    guard let origin, var components = URLComponents(url: origin, resolvingAgainstBaseURL: false),
      let resource = URLComponents(string: value)
    else { return nil }
    components.path = resource.path
    components.percentEncodedQuery = resource.percentEncodedQuery
    return components.url
  }

  private static func item(
    link: LiveTwitchLink, title: String, owner: LiveTwitchUser?, thumbnail: String, duration: Int, views: Int, isLive: Bool
  ) -> LiveVideoItem {
    LiveVideoItem(
      id: url(for: link), title: title, url: url(for: link), thumbnailURL: thumbnail,
      uploaderName: owner?.name ?? "", uploaderURL: owner.map { url(for: .channel($0.login)) } ?? "",
      uploaderAvatarURL: owner?.avatarURL ?? "", duration: Int64(duration), viewCount: Int64(views), uploadDate: "",
      uploaded: 0, streamType: isLive ? "LIVE_STREAM" : "VIDEO_STREAM", isShortFormContent: false, uploaderVerified: false,
      shortDescription: nil, publishedAt: nil, isLive: isLive, isPostLive: false, isLiveContent: isLive, requiresMembership: false
    )
  }

  private static func base(
    _ item: LiveVideoItem, description: String, owner: LiveTwitchUser, isLive: Bool, chapters: [LivePlaybackChapter] = [],
    category: String? = nil
  ) -> LivePlaybackStream {
    LivePlaybackStream(
      id: item.id, title: item.title, uploaderName: owner.name, uploaderURL: item.uploaderURL,
      uploaderAvatarURL: owner.avatarURL, thumbnailURL: item.thumbnailURL, description: description,
      duration: item.duration, viewCount: item.viewCount, likeCount: -1, dislikeCount: -1, uploadDate: "", uploaded: 0,
      uploaderSubscriberCount: -1, uploaderVerified: false, publishedAt: nil, startPosition: 0, hlsURL: "",
      videoStreams: [], audioStreams: [], videoOnlyStreams: [], subtitles: [], chapters: chapters,
      sponsorBlockSegments: [], relatedStreams: [], category: category, isLive: isLive, isPostLive: false, isLiveContent: isLive
    )
  }
}

extension LiveVideoItem {
  var twitchLink: LiveTwitchLink? {
    URL(string: url).flatMap(LiveTwitchLink.target(for:))
  }
}
