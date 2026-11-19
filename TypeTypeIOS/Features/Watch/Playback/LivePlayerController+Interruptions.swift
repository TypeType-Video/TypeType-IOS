import AVFoundation
import Foundation

final class LiveAudioSessionEvents {
  var observations: [NSObjectProtocol] = []
  var resumesAfterInterruption = false

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
        let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt).flatMap(AVAudioSession.RouteChangeReason.init)
        guard reason == .oldDeviceUnavailable else { return }
        MainActor.assumeIsolated { self?.headphonesRemoved() }
      },
    ]
  }

  private func audioInterrupted(_ interruption: LiveAudioInterruption) {
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

  private func headphonesRemoved() {
    audioEvents.resumesAfterInterruption = false
    if state == .playing { pause() }
  }
}

enum LiveAudioInterruption: Equatable {
  case began
  case ended(shouldResume: Bool)
  case unknown

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
