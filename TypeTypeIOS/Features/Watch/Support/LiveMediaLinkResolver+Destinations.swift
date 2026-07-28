import Foundation

extension LiveMediaLinkResolver {
  static func videoDestination(
    for url: URL
  ) -> LiveMediaLinkDestination {
    .video(
      LiveVideoItem(
        id: url.absoluteString,
        title: "Video",
        url: url.absoluteString,
        thumbnailURL: "",
        uploaderName: "",
        uploaderURL: "",
        uploaderAvatarURL: "",
        duration: 0,
        viewCount: 0,
        uploadDate: "",
        uploaded: 0,
        streamType: "VIDEO_STREAM",
        isShortFormContent: false,
        uploaderVerified: false,
        shortDescription: nil,
        publishedAt: nil,
        isLive: false,
        isPostLive: false,
        isLiveContent: false,
        requiresMembership: false
      )
    )
  }

  static func videoDestination(
    for value: String
  ) -> LiveMediaLinkDestination? {
    guard let url = normalizedVideoURL(value) else { return nil }
    return providerDestination(for: url)
  }

  static func channelDestination(
    for value: String
  ) -> LiveMediaLinkDestination? {
    let trimmed = value.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    let normalized: String
    if trimmed.hasPrefix("@") {
      normalized = "https://www.youtube.com/\(trimmed)"
    } else if trimmed.hasPrefix("UC"), trimmed.count == 24 {
      normalized = "https://www.youtube.com/channel/\(trimmed)"
    } else {
      normalized = trimmed
    }
    guard let url = URL(string: normalized),
      let destination = providerDestination(for: url),
      case let .channel(channel) = destination
    else {
      return nil
    }
    return .channel(channel)
  }

  static func playlistDestination(
    for value: String
  ) -> LiveMediaLinkDestination? {
    let trimmed = value.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard let url = URL(string: trimmed),
      let destination = providerDestination(for: url),
      case let .playlist(playlist) = destination
    else {
      return nil
    }
    return .playlist(playlist)
  }

  static func playlistDestination(
    forListID value: String
  ) -> LiveMediaLinkDestination? {
    let trimmed = value.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard !trimmed.isEmpty,
      var components = URLComponents(
        string: "https://www.youtube.com/playlist"
      )
    else {
      return nil
    }
    components.queryItems = [
      URLQueryItem(name: "list", value: trimmed),
    ]
    return components.url.map(playlistDestination(for:))
  }

  static func playlistDestination(
    for url: URL
  ) -> LiveMediaLinkDestination {
    .playlist(
      LivePlaylistResult(
        id: url.absoluteString,
        title: "Playlist",
        url: url.absoluteString,
        thumbnailURL: "",
        uploaderName: "",
        streamCount: 0,
        playlistType: ""
      )
    )
  }

  private static func normalizedVideoURL(_ value: String) -> URL? {
    let trimmed = value.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    if trimmed.range(
      of: #"^[A-Za-z0-9_-]{11}$"#,
      options: .regularExpression
    ) != nil {
      return URL(
        string: "https://www.youtube.com/watch?v=\(trimmed)"
      )
    }
    if trimmed.range(
      of: #"^sm[0-9]+$"#,
      options: [.regularExpression, .caseInsensitive]
    ) != nil {
      return URL(
        string: "https://www.nicovideo.jp/watch/\(trimmed)"
      )
    }
    if trimmed.range(
      of: #"^BV[A-Za-z0-9]{10}(?:\?p=[0-9]+)?$"#,
      options: [.regularExpression, .caseInsensitive]
    ) != nil {
      return URL(
        string: "https://www.bilibili.com/video/\(trimmed)"
      )
    }
    return URL(string: trimmed)
  }
}
