import TypeTypePlayerKit
import UIKit

@MainActor
final class LiveNativePlayback {
  let player: TypeTypePlayer
  let session: LiveSABRPlaybackSession?
  let preparation: LivePlaybackPreparation
  var hasStarted = false
  private var foregroundObservation: NSObjectProtocol?

  init(player: TypeTypePlayer, session: LiveSABRPlaybackSession?, preparation: LivePlaybackPreparation) {
    self.player = player
    self.session = session
    self.preparation = preparation
    foregroundObservation = NotificationCenter.default.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil,
      queue: .main
    ) { [weak player] _ in
      MainActor.assumeIsolated { player?.recoverDecoderIfNeeded() }
    }
  }

  func report(_ time: TimeInterval) {
    Task { [session] in await session?.updatePlayerTime(time) }
  }

  func seek(to time: TimeInterval) {
    player.seek(to: time)
    Task { [session] in await session?.playerSeeked(to: time) }
  }

  func setRate(_ rate: Float) {
    player.setRate(rate)
    Task { [session] in await session?.updatePlaybackRate(rate) }
  }

  func stop() {
    if let foregroundObservation {
      NotificationCenter.default.removeObserver(foregroundObservation)
      self.foregroundObservation = nil
    }
    player.stop()
    Task { [session] in await session?.stopMaintenance() }
  }
}
