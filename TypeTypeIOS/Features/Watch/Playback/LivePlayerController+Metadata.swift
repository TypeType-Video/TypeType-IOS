import Foundation

extension LivePlayerController {
  var isLiveStream: Bool { stream?.isLive == true || video.isLive }

  /// Playback starts from the fast playback stream; full metadata (related
  /// videos, chapters, SponsorBlock, description) replaces it when it arrives.
  func loadFullMetadata(using service: LivePlaybackServiceProtocol) {
    metadataTask?.cancel()
    let videoURL = video.url
    isLoadingFullMetadata = true
    metadataTask = Task { [weak self] in
      let full = try? await service.stream(for: videoURL)
      guard !Task.isCancelled, let self, video.url == videoURL else { return }
      isLoadingFullMetadata = false
      guard let full else { return }
      stream = full
      onMetadataResolved?(video.resolving(with: full))
    }
  }
}
