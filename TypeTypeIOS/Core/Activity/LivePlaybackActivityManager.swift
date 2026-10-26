import ActivityKit
import Foundation

/// Owns the playback Live Activity (Dynamic Island). Content updates ride
/// the playback session's 15s progress loop, so the Island always shows the
/// same position the history page reports. Ending playback ends it.
final class LivePlaybackActivityManager {
  static let shared = LivePlaybackActivityManager()

  private var activity: Activity<PlaybackActivityAttributes>?
  private var lastVideoID: String?

  func update(from snapshot: LivePlaybackActivitySnapshot) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let state = PlaybackActivityAttributes.ContentState(
      title: snapshot.title,
      channelName: snapshot.channelName ?? "",
      thumbnailURL: snapshot.thumbnailURL,
      isPlaying: !snapshot.isPaused,
      positionMilliseconds: snapshot.positionMilliseconds,
      durationMilliseconds: snapshot.durationMilliseconds
    )
    if let activity, lastVideoID == snapshot.videoURL {
      Task {
        await activity.update(ActivityContent(state: state, staleDate: nil))
      }
      return
    }
    // A different video means a fresh activity for the new content.
    end()
    lastVideoID = snapshot.videoURL
    activity = try? Activity.request(
      attributes: PlaybackActivityAttributes(),
      content: ActivityContent(state: state, staleDate: nil),
      pushType: nil
    )
  }

  func end() {
    lastVideoID = nil
    guard let activity else { return }
    self.activity = nil
    Task {
      await activity.end(
        ActivityContent(state: activity.content.state, staleDate: nil),
        dismissalPolicy: .immediate
      )
    }
  }
}
