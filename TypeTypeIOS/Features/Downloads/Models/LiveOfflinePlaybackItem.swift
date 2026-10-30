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

  var watchVideo: LiveVideoItem {
    let meta = record.metadata
    let avatar: String = meta?.localAvatarFileName.map {
      fileURL.deletingLastPathComponent().appendingPathComponent($0)
        .absoluteString
    } ?? meta?.uploaderAvatarURL ?? ""
    return LiveVideoItem(
      id: record.id,
      title: record.title,
      url: record.videoURL,
      thumbnailURL: meta?.thumbnailURL ?? "",
      uploaderName: meta?.uploaderName ?? "",
      uploaderURL: meta?.uploaderURL ?? "",
      uploaderAvatarURL: avatar,
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
      likeCount: meta?.likeCount ?? -1,
      dislikeCount: meta?.dislikeCount ?? -1,
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
  func installOffline(stream: LivePlaybackStream, fileURL: URL) async {
    isOfflineContent = true
    state = .loading
    do {
      try await AudioSessionConfigurator.configure(backgroundAudio: true)
      guard !Task.isCancelled else { return }
      self.stream = stream
      installPlayerItem(at: fileURL, autoplay: true)
    } catch {
      state = .failed("The audio session could not be configured.")
    }
  }
}
