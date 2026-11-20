import MediaPlayer
import UIKit

@MainActor
final class LiveNowPlaying {
  struct Commands {
    let play: () -> Void
    let pause: () -> Void
    let seek: (TimeInterval) -> Void
    let skip: (TimeInterval) -> Void
    var next: (() -> Void)?
    var previous: (() -> Void)?
    var isLive = false
  }

  private var targets: [(MPRemoteCommand, Any)] = []
  private var info: [String: Any] = [:]
  private var artworkTask: Task<Void, Never>?

  func activate(title: String, artist: String, duration: TimeInterval, artworkURL: URL?, commands: Commands) {
    deactivate()
    info = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: artist,
      MPMediaItemPropertyPlaybackDuration: duration,
      MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.video.rawValue,
      MPNowPlayingInfoPropertyIsLiveStream: commands.isLive,
    ]
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    register(commands)
    guard let artworkURL else { return }
    artworkTask = Task { [weak self] in
      guard
        let (data, _) = try? await URLSession.shared.data(from: artworkURL),
        let image = UIImage(data: data),
        !Task.isCancelled, let self
      else {
        return
      }
      info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
      MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
  }

  func update(elapsed: TimeInterval, rate: Float, duration: TimeInterval) {
    guard !info.isEmpty else { return }
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
    info[MPNowPlayingInfoPropertyPlaybackRate] = rate
    info[MPMediaItemPropertyPlaybackDuration] = duration
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  func deactivate() {
    artworkTask?.cancel()
    artworkTask = nil
    targets.forEach { command, target in command.removeTarget(target) }
    targets = []
    guard !info.isEmpty else { return }
    info = [:]
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }

  private func register(_ commands: Commands) {
    let center = MPRemoteCommandCenter.shared()
    center.skipForwardCommand.preferredIntervals = [10]
    center.skipBackwardCommand.preferredIntervals = [10]
    add(center.playCommand) { _ in commands.play() }
    add(center.pauseCommand) { _ in commands.pause() }
    add(center.togglePlayPauseCommand) { [weak self] _ in
      (self?.info[MPNowPlayingInfoPropertyPlaybackRate] as? Float ?? 0) > 0 ? commands.pause() : commands.play()
    }
    // The lock screen shows track buttons only while the skip commands are off: a queue gets tracks, a single video ±10 s.
    let tracks = commands.next != nil || commands.previous != nil
    center.skipForwardCommand.isEnabled = !tracks
    center.skipBackwardCommand.isEnabled = !tracks
    center.nextTrackCommand.isEnabled = commands.next != nil
    center.previousTrackCommand.isEnabled = commands.previous != nil
    if let next = commands.next { add(center.nextTrackCommand) { _ in next() } }
    if let previous = commands.previous { add(center.previousTrackCommand) { _ in previous() } }
    if !tracks {
      add(center.skipForwardCommand) { _ in commands.skip(10) }
      add(center.skipBackwardCommand) { _ in commands.skip(-10) }
    }
    center.changePlaybackPositionCommand.isEnabled = !commands.isLive
    guard !commands.isLive else { return }
    add(center.changePlaybackPositionCommand) { event in
      guard let event = event as? MPChangePlaybackPositionCommandEvent else { return }
      commands.seek(event.positionTime)
    }
  }

  private func add(_ command: MPRemoteCommand, _ action: @escaping (MPRemoteCommandEvent) -> Void) {
    command.isEnabled = true
    let target = command.addTarget { event in
      MainActor.assumeIsolated { action(event) }
      return .success
    }
    targets.append((command, target))
  }
}
