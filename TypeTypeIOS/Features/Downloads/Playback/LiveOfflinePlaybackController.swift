import AVFoundation
import Combine
import Foundation

@MainActor
final class LiveOfflinePlaybackController: ObservableObject {
  let player: AVPlayer

  @Published private(set) var isPlaying = false
  @Published private(set) var position: TimeInterval = 0
  @Published private(set) var duration: TimeInterval = 0
  @Published private(set) var errorMessage: String?

  private var timeObserver: Any?
  private var itemObservation: NSKeyValueObservation?
  private var endObservation: NSObjectProtocol?

  init(fileURL: URL) {
    player = AVPlayer(url: fileURL)
    player.automaticallyWaitsToMinimizeStalling = false
    observePlayer()
  }

  deinit {
    if let timeObserver {
      player.removeTimeObserver(timeObserver)
    }
    if let endObservation {
      NotificationCenter.default.removeObserver(endObservation)
    }
  }

  func start() {
    Task { [weak self] in
      do {
        try await DemoAudioSessionConfigurator.configure(
          backgroundAudio: true
        )
      } catch {
        self?.errorMessage = "The audio session could not be configured."
        return
      }
      self?.player.play()
      self?.isPlaying = true
    }
  }

  func stop() {
    player.pause()
    isPlaying = false
  }

  func togglePlayback() {
    if player.timeControlStatus == .playing {
      player.pause()
      isPlaying = false
    } else {
      player.play()
      isPlaying = true
    }
  }

  func seek(to seconds: TimeInterval) {
    let target = min(max(seconds, 0), max(duration, 0))
    player.seek(
      to: CMTime(seconds: target, preferredTimescale: 600),
      toleranceBefore: .zero,
      toleranceAfter: .zero
    )
    position = target
  }

  func skip(by seconds: TimeInterval) {
    seek(to: position + seconds)
  }

  private func observePlayer() {
    let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
    timeObserver = player.addPeriodicTimeObserver(
      forInterval: interval,
      queue: .main
    ) { [weak self] time in
      guard let self else { return }
      Task { @MainActor in
        let seconds = time.seconds
        if seconds.isFinite {
          self.position = max(seconds, 0)
        }
        if let item = self.player.currentItem {
          let itemDuration = item.duration.seconds
          if itemDuration.isFinite, itemDuration > 0 {
            self.duration = itemDuration
          }
        }
        self.isPlaying = self.player.timeControlStatus == .playing
      }
    }

    guard let item = player.currentItem else { return }
    itemObservation = item.observe(
      \.status,
      options: [.initial, .new]
    ) { [weak self] item, _ in
      Task { @MainActor in
        guard let self else { return }
        switch item.status {
        case .failed:
          self.errorMessage =
            item.error?.localizedDescription
            ?? "This downloaded file cannot be played."
          self.isPlaying = false
        case .readyToPlay:
          let seconds = item.duration.seconds
          if seconds.isFinite, seconds > 0 {
            self.duration = seconds
          }
          self.errorMessage = nil
        case .unknown:
          break
        @unknown default:
          break
        }
      }
    }
    endObservation = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.isPlaying = false
      }
    }
  }
}
