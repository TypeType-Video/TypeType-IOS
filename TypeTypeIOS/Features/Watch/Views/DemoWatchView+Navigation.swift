import Foundation
import SwiftUI

extension DemoWatchView {
  var contentPadding: CGFloat {
    horizontalSizeClass == .regular ? 24 : 16
  }

  var playerHorizontalPadding: CGFloat {
    horizontalSizeClass == .regular && !session.preferences.cinemaMode ? 24 : 0
  }

  var playerShape: RoundedRectangle {
    RoundedRectangle(
      cornerRadius:
        horizontalSizeClass == .regular && !session.preferences.cinemaMode
        ? 16
        : 0,
      style: .continuous
    )
  }

  func selectRelated(_ nextVideo: DemoVideo) {
    if nextVideo.id.contains("big-buck") {
      controller.seek(to: 0)
      controller.start()
      toastMessage = "Restarted Big Buck Bunny"
    } else {
      keepsPlaybackExpanded = true
      selectedVideo = nextVideo
    }
  }

  func previewPlaylistEnd(_ nextVideo: DemoVideo) {
    let presentation = DemoAutoplayPolicy.presentation(
      autoplay: autoplay,
      source: .playlist,
      skipsPlaylistScreen: session.preferences.skipPlaylistAutoplayScreen,
      countdownSeconds: session.preferences.autoplayCountdownSeconds
    )
    switch presentation {
    case .none:
      toastMessage = "Autoplay is disabled"
    case .immediate:
      selectRelated(nextVideo)
    case .countdown:
      autoplayTarget = nextVideo
    }
  }

  func handlePlaybackEnded() {
    guard let target = nextAutoplayTarget else {
      toastMessage = "Playback finished"
      return
    }
    previewPlaylistEnd(target)
  }

  func presentTestPlaybackEndIfRequested() {
#if DEBUG
    guard
      ProcessInfo.processInfo.environment[
        "TYPETYPE_UI_TEST_PLAYER_ENDED"
      ] == "1"
    else {
      return
    }
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(400))
      handlePlaybackEnded()
    }
#endif
  }

  func playAutoplayTarget() {
    guard let target = autoplayTarget else { return }
    autoplayTarget = nil
    selectRelated(target)
  }

  func cancelAutoplay() {
    autoplayTarget = nil
  }

  func openChannel() {
    keepsPlaybackExpanded = true
    selectedChannel =
      DemoSearchCatalog.channels.first { $0.id == channelID }
      ?? DemoSearchCatalog.channels.first
  }

  var channelID: String {
    DemoSubscriptionCatalog.channelID(for: video) ?? "self-hosted"
  }

  private var nextAutoplayTarget: DemoVideo? {
    let catalog =
      DemoSearchCatalog.videos
      + DemoWatchCatalog.queue
      + DemoWatchCatalog.relatedVideos
    let unique = Dictionary(
      catalog.map { ($0.id, $0) },
      uniquingKeysWith: { first, _ in first }
    )
    if let queued = session.queueOrder
      .compactMap({ unique[$0] })
      .first(where: { $0.id != video.id }) {
      return queued
    }
    return DemoWatchCatalog.relatedVideos.first { $0.id != video.id }
  }

  func seekFromText(_ seconds: Double) {
    controller.seek(to: seconds)
    toastMessage = "Jumped to \(formattedTimestamp(seconds))"
  }

  func routeLink(_ url: URL) {
    if let linkedVideo = DemoMediaLinkResolver.internalVideo(for: url) {
      selectRelated(linkedVideo)
    } else {
      pendingExternalURL = url
    }
  }

  private func formattedTimestamp(_ seconds: Double) -> String {
    let value = max(0, Int(seconds))
    let hours = value / 3_600
    let minutes = (value % 3_600) / 60
    let remainder = value % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, remainder)
    }
    return String(format: "%d:%02d", minutes, remainder)
  }
}
