import Foundation

struct LiveOfflinePlaybackItem: Identifiable {
  let record: LiveManagedDownload
  let fileURL: URL

  var id: String {
    record.id
  }

  var isAudioOnly: Bool {
    record.options.mode.caseInsensitiveCompare("audio") == .orderedSame
  }

  /// The watch page's video, built from the thin download record (title and
  /// URL are all a managed download keeps).
  var watchVideo: LiveVideoItem {
    let meta = record.metadata
    return LiveVideoItem(
      id: record.id,
      title: record.title,
      url: record.videoURL,
      thumbnailURL: meta?.thumbnailURL ?? "",
      uploaderName: meta?.uploaderName ?? "",
      uploaderURL: meta?.uploaderURL ?? "",
      uploaderAvatarURL: meta?.uploaderAvatarURL ?? "",
      duration: meta?.duration ?? 0,
      viewCount: meta?.viewCount ?? 0,
      uploadDate: meta?.uploadDate ?? "",
      uploaded: meta?.uploaded ?? 0,
      streamType: meta?.streamType ?? "video",
      isShortFormContent: meta?.isShortFormContent ?? false,
      uploaderVerified: meta?.uploaderVerified ?? false,
      shortDescription: meta?.shortDescription,
      publishedAt: meta?.publishedAt,
      isLive: meta?.isLive ?? false,
      isPostLive: meta?.isPostLive ?? false,
      isLiveContent: meta?.isLiveContent ?? false,
      requiresMembership: meta?.requiresMembership ?? false
    )
  }

  /// Synthetic stream metadata so the watch page renders without a server.
  var watchStream: LivePlaybackStream {
    let meta = record.metadata
    return LivePlaybackStream(
      id: record.id,
      title: record.title,
      uploaderName: meta?.uploaderName ?? "",
      uploaderURL: meta?.uploaderURL ?? "",
      uploaderAvatarURL: meta?.uploaderAvatarURL ?? "",
      thumbnailURL: meta?.thumbnailURL ?? "",
      description: meta?.shortDescription ?? "",
      duration: meta?.duration ?? 0,
      viewCount: meta?.viewCount ?? 0,
      likeCount: -1,
      dislikeCount: -1,
      uploadDate: "",
      uploaded: meta?.uploaded ?? 0,
      uploaderSubscriberCount: 0,
      uploaderVerified: meta?.uploaderVerified ?? false,
      publishedAt: meta?.publishedAt,
      startPosition: 0,
      hlsURL: "",
      videoStreams: [],
      audioStreams: [],
      videoOnlyStreams: [],
      subtitles: [],
      chapters: [],
      sponsorBlockSegments: [],
      relatedStreams: [],
      category: nil,
      isLive: false,
      isPostLive: false,
      isLiveContent: false
    )
  }
}

extension LivePlayerController {
  /// Offline playback: a local file through the full player stage — no
  /// server loading path, no full-metadata fetch.
  func installOffline(stream: LivePlaybackStream, fileURL: URL) {
    self.stream = stream
    state = .loading
    installPlayerItem(at: fileURL, autoplay: true)
  }
}
