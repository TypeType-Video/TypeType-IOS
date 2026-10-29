import AVFoundation
import SwiftUI

@MainActor
final class DemoPlayerController: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case failed(String)
  }

  let player = AVPlayer()
  @Published private(set) var state: State = .idle
  @Published private(set) var playbackEndSequence = 0
  @Published private(set) var playbackStartSequence = 0
  @Published private(set) var audioGainPercent = 100
  @Published private(set) var audioLevel: Float = 0

  private var itemObservation: NSKeyValueObservation?
  private var playbackObservation: NSKeyValueObservation?
  private var endObservation: NSObjectProtocol?
  private var loopsPlayback = false

  func start() {
    playbackStartSequence += 1
    if player.currentItem != nil {
      player.play()
      return
    }

    state = .loading
    let item = AVPlayerItem(url: DemoBigBuckBunnySource.videoURL)
    observe(item)
    player.replaceCurrentItem(with: item)
    if audioGainPercent > 100 {
      applyAudioGain(to: item)
    }
    player.play()
  }

  func stop() {
    player.pause()
  }

  func togglePlayback() {
    if player.timeControlStatus == .playing {
      player.pause()
    } else {
      start()
    }
  }

  func seek(to seconds: Double) {
    let time = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
    player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
  }

  func setPlaybackRate(_ rate: Float) {
    player.defaultRate = rate
    if player.timeControlStatus == .playing {
      player.rate = rate
    }
  }

  func setLooping(_ enabled: Bool) {
    loopsPlayback = enabled
  }

  func setAudioGain(percent: Int) {
    audioGainPercent = min(300, max(100, percent))
    guard let item = player.currentItem else { return }
    applyAudioGain(to: item)
  }

  private func observePlaybackEnd(for item: AVPlayerItem) {
    if let endObservation {
      NotificationCenter.default.removeObserver(endObservation)
    }
    endObservation = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        guard let self else { return }
        if loopsPlayback {
          seek(to: 0)
          start()
        } else {
          state = .paused
          playbackEndSequence += 1
        }
      }
    }
  }

  func setBackgroundAudioEnabled(_ enabled: Bool) {
    Task { [weak self] in
      do {
        try await DemoAudioSessionConfigurator.configure(backgroundAudio: enabled)
      } catch {
        self?.state = .failed("The audio session could not be configured.")
      }
    }
  }

  func retry() {
    itemObservation = nil
    playbackObservation = nil
    player.replaceCurrentItem(with: nil)
    state = .idle
    start()
  }

  private func observe(_ item: AVPlayerItem) {
    observePlaybackEnd(for: item)
    itemObservation = item.observe(
      \.status,
      options: [.initial, .new]
    ) { [weak self] item, _ in
      Task { @MainActor [weak self] in
        guard let self else { return }
        switch item.status {
        case .unknown:
          state = .loading
        case .readyToPlay:
          state = player.timeControlStatus == .playing ? .playing : .ready
        case .failed:
          state = .failed(DemoPlaybackErrorFormatter.message(for: item.error))
        @unknown default:
          state = .failed("The player reported an unknown state.")
        }
      }
    }

    playbackObservation = player.observe(
      \.timeControlStatus,
      options: [.new]
    ) { [weak self] player, _ in
      Task { @MainActor [weak self] in
        guard let self else { return }
        switch player.timeControlStatus {
        case .paused:
          if state == .playing {
            state = .paused
          }
        case .waitingToPlayAtSpecifiedRate:
          state = .loading
        case .playing:
          state = .playing
        @unknown default:
          break
        }
      }
    }
  }

  private func applyAudioGain(to item: AVPlayerItem) {
    let gain = Float(audioGainPercent) / 100
    guard gain > 1 else {
      if item.audioMix != nil {
        item.audioMix = nil
      }
      audioLevel = 0
      return
    }
    Task { @MainActor [weak self, weak item] in
      guard let self, let item else { return }
      let tracks = try? await item.asset.loadTracks(withMediaType: .audio)
      guard player.currentItem === item, let tracks, !tracks.isEmpty else {
        return
      }
      let parameters = tracks.map { track in
        let parameter = AVMutableAudioMixInputParameters(track: track)
        parameter.setVolume(1, at: .zero)
        parameter.audioTapProcessor = DemoAudioGainProcessor.makeTap(
          gain: gain
        ) { [weak self] level in
          Task { @MainActor [weak self] in
            self?.audioLevel = level
          }
        }
        return parameter
      }
      let mix = AVMutableAudioMix()
      mix.inputParameters = parameters
      item.audioMix = mix
    }
  }
}
