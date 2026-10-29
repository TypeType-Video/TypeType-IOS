import ActivityKit
import Foundation

/// Drives the audio-only playback Live Activity: started when the app goes
/// to the background with playback running, kept in sync while it runs, and
/// ended when playback stops or the app returns to the foreground.
@MainActor
final class LivePlaybackActivityController {
  static let shared = LivePlaybackActivityController()

  private var activity: Activity<LivePlaybackActivityAttributes>?
  private weak var controller: LivePlayerController?
  private var updateTask: Task<Void, Never>?

  func attach(_ controller: LivePlayerController) {
    self.controller = controller
  }

  /// Begins the island for the current playback, if the device allows
  /// Live Activities and none is running.
  func startIfPossible() {
    guard activity == nil,
      ActivityAuthorizationInfo().areActivitiesEnabled,
      let controller
    else { return }
    let content = ActivityContent(
      state: Self.contentState(for: controller),
      staleDate: nil
    )
    do {
      activity = try Activity.request(
        attributes: LivePlaybackActivityAttributes(
          videoURL: controller.video.url
        ),
        content: content
      )
    } catch {
      AppLogger.playback.error(
        "live activity: start failed \(error.localizedDescription, privacy: .public)"
      )
    }
    startUpdates()
  }

  /// Ends the island (no-op when none runs).
  func end() {
    updateTask?.cancel()
    updateTask = nil
    guard let activity else { return }
    self.activity = nil
    Task { await activity.end(nil, dismissalPolicy: .immediate) }
  }

  private func startUpdates() {
    updateTask?.cancel()
    updateTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        await self?.tick()
      }
    }
  }

  private func tick() async {
    guard let controller, let activity else { return }
    // Playback ended while the app was away: the island has nothing to say.
    switch controller.state {
    case .idle, .failed:
      end()
      return
    case .ready, .loading, .paused, .playing:
      break
    }
    let content = ActivityContent(
      state: Self.contentState(for: controller),
      staleDate: nil
    )
    await activity.update(content)
  }

  private static func contentState(
    for controller: LivePlayerController
  ) -> LivePlaybackActivityAttributes.ContentState {
    let progress: Double
    if controller.duration > 0 {
      progress = min(max(controller.position / controller.duration, 0), 1)
    } else {
      progress = 0
    }
    return LivePlaybackActivityAttributes.ContentState(
      title: controller.stream?.title ?? controller.video.title,
      channel: controller.stream?.uploaderName ?? controller.video.uploaderName,
      isPlaying: controller.state == .playing,
      isLive: controller.isLiveStream,
      progress: progress
    )
  }
}
