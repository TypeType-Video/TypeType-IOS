import AVFoundation
import Foundation

final class LiveAudioSessionEvents {
  var observations: [NSObjectProtocol] = []
  var resumesAfterInterruption = false
  var bitRate = LiveBackgroundBitRate()

  deinit {
    observations.forEach { NotificationCenter.default.removeObserver($0) }
  }
}

struct LiveQueueNavigation {
  let hasNext: () -> Bool
  let hasPrevious: () -> Bool
  let next: () -> Void
  let previous: () -> Void
}

extension LivePlayerController {
  // The native player renders its own audio, so the system does not pause it for a call or when headphones go away.
  func observeAudioSessionEvents() {
    let center = NotificationCenter.default
    audioEvents.observations = [
      center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
        let info = LiveAudioInterruption(note.userInfo)
        MainActor.assumeIsolated { self?.audioInterrupted(info) }
      },
      center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
        guard LiveAudioInterruption.lostPersonalOutput(note.userInfo) else { return }
        MainActor.assumeIsolated { self?.headphonesRemoved() }
      },
    ]
  }

  private func audioInterrupted(_ interruption: LiveAudioInterruption) {
    AppLogger.playback.notice("audio interruption \(String(describing: interruption), privacy: .public) state=\(String(describing: self.state), privacy: .public)")
    switch interruption {
    case .began:
      audioEvents.resumesAfterInterruption = state == .playing
      if state == .playing { pause() }
    case let .ended(shouldResume):
      defer { audioEvents.resumesAfterInterruption = false }
      guard shouldResume, audioEvents.resumesAfterInterruption, !isTornDown else { return }
      try? AVAudioSession.sharedInstance().setActive(true)
      resume()
    case .unknown:
      break
    }
  }

  // AVPlayer pauses by itself when headphones go away; only the native renderer needs it.
  private func headphonesRemoved() {
    audioEvents.resumesAfterInterruption = false
    guard nativePlayback != nil, state == .playing else { return }
    AppLogger.playback.notice("headphones removed, pausing")
    pause()
  }
}

enum LiveAudioInterruption: Equatable {
  case began
  case ended(shouldResume: Bool)
  case unknown

  static let personalOutputs: Set<AVAudioSession.Port> = [
    .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .lineOut, .usbAudio, .carAudio,
  ]

  static func lostPersonalOutput(_ userInfo: [AnyHashable: Any]?) -> Bool {
    let reason = (userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt).flatMap(AVAudioSession.RouteChangeReason.init)
    guard reason == .oldDeviceUnavailable,
      let previous = userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
    else { return false }
    return previous.outputs.contains { personalOutputs.contains($0.portType) }
  }

  init(_ userInfo: [AnyHashable: Any]?) {
    guard let raw = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: raw)
    else {
      self = .unknown
      return
    }
    switch type {
    case .began:
      self = .began
    case .ended:
      let options = (userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt).map(AVAudioSession.InterruptionOptions.init) ?? []
      self = .ended(shouldResume: options.contains(.shouldResume))
    @unknown default:
      self = .unknown
    }
  }
}
