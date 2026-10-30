import Foundation

extension LiveVideoMetadataContentView {
  var branding: LiveVideoBranding {
    deArrowStore.branding(for: video)
  }

  var playbackDescription: String? {
    let full = playerController.stream.map {
      stream in
        LiveDescriptionTextFormatter.displayText(
          stream.description,
          sourceURL: resolvedVideo.url
        )
    }
    if let full, !full.isEmpty { return full }
    return video.shortDescription
  }

  var posterURL: URL? {
    guard let value = playerController.stream?.thumbnailURL,
      let url = URL(string: value)
    else {
      return branding.thumbnailURL
    }
    return url
  }

  var resolvedVideo: LiveVideoItem {
    video.resolving(with: playerController.stream)
  }

  var libraryActionsIdentity: String {
    [
      resolvedVideo.canonicalID,
      resolvedVideo.title,
      resolvedVideo.uploaderName,
    ].joined(separator: ":")
  }

  var engagementIdentity: String {
    [
      resolvedVideo.uploaderURL,
      String(playerController.stream?.likeCount ?? -1),
      String(playerController.stream?.dislikeCount ?? -1),
    ].joined(separator: ":")
  }

  var hasPersistentAccount: Bool {
    guard let serverID = dependencies.serverStore.selectedServerID(),
      let session = dependencies.sessionStore.session(
        forServerID: serverID
      )
    else {
      return false
    }
    return session.accountIdentifier != nil
  }

  func routeLink(_ url: URL) {
    switch LiveMediaLinkResolver.destination(
      for: url,
      serverURL: dependencies.serverStore.selectedServer()?.baseURL
    ) {
    case let .video(linkedVideo):
      playbackCoordinator.open(linkedVideo)
    case let .channel(channelURL):
      selectedChannelURL = channelURL
    case let .playlist(playlist):
      selectedPublicPlaylist = playlist
    case nil:
      pendingExternalURL = url
    }
  }

  var channelMetadataIdentity: String {
    [
      resolvedVideo.uploaderURL,
      String(playerController.stream?.uploaderSubscriberCount ?? -1),
    ].joined(separator: ":")
  }
}
