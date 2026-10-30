import Foundation

extension LivePlayerController {
  var isLiveStream: Bool { stream?.isLive == true || video.isLive }

  func loadFullMetadata(using service: LivePlaybackServiceProtocol) {
    metadataTask?.cancel()
    let videoURL = video.url
    isLoadingFullMetadata = true
    metadataTask = Task { [weak self] in
      do {
        let full = try await service.stream(for: videoURL)
        guard !Task.isCancelled, let self, video.url == videoURL else { return }
        isLoadingFullMetadata = false
        AppLogger.playback.info(
          "chapters: full metadata resolved count=\(full.chapters.count, privacy: .public) sponsor=\(full.sponsorBlockSegments.count, privacy: .public)"
        )
        stream = full
        onMetadataResolved?(video.resolving(with: full))
      } catch {
        guard !Task.isCancelled, let self else { return }
        isLoadingFullMetadata = false
        AppLogger.playback.error(
          "chapters: full metadata failed \(error.localizedDescription, privacy: .public)"
        )
      }
    }
  }
}
