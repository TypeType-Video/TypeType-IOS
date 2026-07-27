import Foundation

extension LiveVideoItem {
  func resolving(with stream: LivePlaybackStream?) -> LiveVideoItem {
    guard let stream else { return self }
    return LiveVideoItem(
      id: stream.id.isEmpty ? id : stream.id,
      title: stream.title.isEmpty ? title : stream.title,
      url: url,
      thumbnailURL: stream.thumbnailURL.isEmpty
        ? thumbnailURL
        : stream.thumbnailURL,
      uploaderName: stream.uploaderName.isEmpty
        ? uploaderName
        : stream.uploaderName,
      uploaderURL: stream.uploaderURL.isEmpty
        ? uploaderURL
        : stream.uploaderURL,
      uploaderAvatarURL: stream.uploaderAvatarURL.isEmpty
        ? uploaderAvatarURL
        : stream.uploaderAvatarURL,
      duration: stream.duration > 0 ? stream.duration : duration,
      viewCount: stream.viewCount > 0 ? stream.viewCount : viewCount,
      uploadDate: uploadDate,
      uploaded: uploaded,
      streamType: streamType.isEmpty ? "VIDEO_STREAM" : streamType,
      isShortFormContent: isShortFormContent,
      uploaderVerified: uploaderVerified,
      shortDescription: stream.description.isEmpty
        ? shortDescription
        : stream.description,
      publishedAt: publishedAt,
      isLive: stream.isLive,
      isPostLive: stream.isPostLive,
      isLiveContent: stream.isLiveContent,
      requiresMembership: requiresMembership
    )
  }
}
