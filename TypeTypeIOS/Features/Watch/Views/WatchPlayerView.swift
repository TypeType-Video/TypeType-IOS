import AVKit
import Foundation
import SwiftUI

struct WatchPlayerView: View {
  let stream: WatchStream
  let initialPositionMs: Int64
  let onTimeUpdate: (Int64) -> Void
  let onPause: () -> Void
  let onEnded: () -> Void
  let onError: (String) -> Void

  @StateObject private var controller = WatchPlayerController()

  var body: some View {
    Group {
      if let player = controller.player {
        VideoPlayer(player: player)
          .frame(maxWidth: .infinity)
          .aspectRatio(16 / 9, contentMode: .fit)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      } else {
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(TypeTypeColor.card)
          ProgressView("Preparing player...")
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
      }
    }
    .task(id: "\(stream.id)-\(initialPositionMs)") {
      controller.configure(
        stream: stream,
        initialPositionMs: initialPositionMs,
        onTimeUpdate: onTimeUpdate,
        onPause: onPause,
        onEnded: onEnded,
        onError: onError
      )
    }
    .onDisappear {
      controller.teardown()
    }
  }
}

@MainActor
private final class WatchPlayerController: ObservableObject {
  @Published private(set) var player: AVPlayer?

  private var timeObserver: Any?
  private var endObserver: NSObjectProtocol?
  private var itemObservation: NSKeyValueObservation?
  private var rateObservation: NSKeyValueObservation?
  private var didReachEnd: Bool = false

  private var onTimeUpdate: ((Int64) -> Void)?
  private var onPause: (() -> Void)?
  private var onEnded: (() -> Void)?
  private var onError: ((String) -> Void)?

  func configure(
    stream: WatchStream,
    initialPositionMs: Int64,
    onTimeUpdate: @escaping (Int64) -> Void,
    onPause: @escaping () -> Void,
    onEnded: @escaping () -> Void,
    onError: @escaping (String) -> Void
  ) {
    teardown()
    self.onTimeUpdate = onTimeUpdate
    self.onPause = onPause
    self.onEnded = onEnded
    self.onError = onError

    guard let url = stream.playbackURL else {
      onError("No playable stream URL found.")
      return
    }

    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.automaticallyWaitsToMinimizeStalling = true
    self.player = player

    itemObservation = item.observe(\.status, options: [.new]) { [weak self] observedItem, _ in
      guard let self else { return }
      Task { @MainActor in
        if observedItem.status == .failed {
          self.onError?("Playback failed for this stream.")
        }
      }
    }

    rateObservation = player.observe(\.rate, options: [.old, .new]) { [weak self] _, change in
      guard let self else { return }
      guard !self.didReachEnd else { return }
      let oldRate = change.oldValue ?? 0
      let newRate = change.newValue ?? 0
      if oldRate > 0, newRate == 0 {
        Task { @MainActor in
          self.onPause?()
        }
      }
    }

    endObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      guard let self else { return }
      self.didReachEnd = true
      self.onEnded?()
    }

    let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      guard let self else { return }
      let ms = Int64(max(0, time.seconds) * 1_000)
      self.onTimeUpdate?(ms)
    }

    if initialPositionMs > 0 {
      let seconds = Double(initialPositionMs) / 1_000
      let seekTime = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
      player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
  }

  func teardown() {
    if let timeObserver, let player {
      player.removeTimeObserver(timeObserver)
    }
    if let endObserver {
      NotificationCenter.default.removeObserver(endObserver)
    }
    timeObserver = nil
    endObserver = nil
    itemObservation = nil
    rateObservation = nil
    player?.pause()
    player = nil
    didReachEnd = false
    onTimeUpdate = nil
    onPause = nil
    onEnded = nil
    onError = nil
  }
}
