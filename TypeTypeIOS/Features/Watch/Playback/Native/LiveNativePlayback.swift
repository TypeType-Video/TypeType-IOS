import TypeTypePlayerKit
import UIKit

@MainActor
final class LiveNativePlayback {
  let player: TypeTypePlayer
  let session: LiveSABRPlaybackSession?
  let preparation: LivePlaybackPreparation
  let pictureInPictureSource: LiveNativePictureInPictureSource
  let nowPlaying = LiveNowPlaying()
  let layerOwner: LiveNativeLayerOwner
  var hasStarted = false
  private var foregroundObservation: NSObjectProtocol?

  init(
    player: TypeTypePlayer,
    session: LiveSABRPlaybackSession?,
    preparation: LivePlaybackPreparation,
    pictureInPictureSource: LiveNativePictureInPictureSource
  ) {
    self.player = player
    self.session = session
    self.preparation = preparation
    self.pictureInPictureSource = pictureInPictureSource
    layerOwner = LiveNativeLayerOwner(layer: player.videoLayer)
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
    nowPlaying.deactivate()
    player.stop()
    Task { [session] in await session?.stopMaintenance() }
  }
}
