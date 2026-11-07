import Foundation
@testable import TypeTypeIOS

enum LiveVideoItemFixture {
  static func make(
    id: String = "video-1",
    url: String = "https://www.youtube.com/watch?v=video-1",
    title: String = "A useful TypeType recommendation",
    isShort: Bool = false,
    streamType: String = "VIDEO_STREAM",
    publishedAt: Int64? = 1_785_063_770_906
  ) -> LiveVideoItem {
    LiveVideoItem(
      id: id,
      title: title,
      url: url,
      thumbnailURL: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg",
      uploaderName: "TypeType",
      uploaderURL: "https://www.youtube.com/@typetype",
      uploaderAvatarURL: "https://example.test/avatar.jpg",
      duration: 596,
      viewCount: 12_345,
      uploadDate: "2026-07-26",
      uploaded: -1,
      streamType: streamType,
      isShortFormContent: isShort,
      uploaderVerified: true,
      shortDescription: "A deterministic fixture.",
      publishedAt: publishedAt,
      isLive: false,
      isPostLive: false,
      isLiveContent: false,
      requiresMembership: false
    )
  }
}
