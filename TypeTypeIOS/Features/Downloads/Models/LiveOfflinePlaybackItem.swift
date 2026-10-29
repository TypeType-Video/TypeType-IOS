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
    LiveVideoItem(
      id: record.id,
      title: record.title,
      url: record.videoURL,
      thumbnailURL: "",
      uploaderName: "",
      uploaderURL: "",
      uploaderAvatarURL: "",
      duration: 0,
      viewCount: 0,
      uploadDate: "",
      uploaded: 0,
      streamType: "video",
      isShortFormContent: false,
      uploaderVerified: false,
      shortDescription: nil,
      publishedAt: nil,
      isLive: false,
      isPostLive: false,
      isLiveContent: false,
      requiresMembership: false
    )
  }

  /// Synthetic stream metadata so the watch page renders without a server.
  var watchStream: LivePlaybackStream {
    LivePlaybackStream(
      id: record.id,
      title: record.title,
      uploaderName: "",
      uploaderURL: "",
      uploaderAvatarURL: "",
      thumbnailURL: "",
      description: "",
      duration: 0,
      viewCount: 0,
      likeCount: -1,
      dislikeCount: -1,
      uploadDate: "",
      uploaded: 0,
      uploaderSubscriberCount: 0,
      uploaderVerified: false,
      publishedAt: nil,
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
