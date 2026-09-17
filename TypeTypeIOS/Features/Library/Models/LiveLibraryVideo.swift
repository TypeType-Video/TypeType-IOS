import Foundation

struct LiveLibraryVideo: Equatable, Identifiable {
  let url: String
  let title: String
  let thumbnail: String
  let duration: Int64
  let channelName: String
  let channelURL: String
  let channelAvatar: String
  let viewCount: Int64
  let publishedAt: Int64
  let savedAt: Int64

  var id: String { url }

  var video: LiveVideoItem {
    LiveVideoItem(
      id: url,
      title: title,
      url: url,
      thumbnailURL: thumbnail,
      uploaderName: channelName,
      uploaderURL: channelURL,
      uploaderAvatarURL: channelAvatar,
      duration: duration,
      viewCount: viewCount,
      uploadDate: "",
      uploaded: publishedAt,
      streamType: "video",
      isShortFormContent: false,
      uploaderVerified: false,
      shortDescription: nil,
      publishedAt: publishedAt >= 0 ? publishedAt : nil,
      isLive: false,
      isPostLive: false,
      isLiveContent: false,
      requiresMembership: false
    )
  }
}

enum LiveLibraryCollectionKind: String, Identifiable {
  case favorites
  case watchLater

  var id: String { rawValue }

  var title: String {
    switch self {
    case .favorites:
      return String(localized: "Favorites")
    case .watchLater:
      return String(localized: "Watch later")
    }
  }

  var symbol: String {
    switch self {
    case .favorites:
      return "heart.fill"
    case .watchLater:
      return "clock.badge.plus"
    }
  }
}
