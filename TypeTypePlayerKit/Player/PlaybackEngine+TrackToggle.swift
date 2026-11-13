import AVFoundation

extension PlaybackEngine {
  func setTrack(_ kind: MP4TrackKind, enabled: Bool) {
    if enabled {
      guard disabledKinds.remove(kind) != nil else { return }
      seek(to: max(renderer.currentTime.seconds, 0))
      return
    }
    guard kind == .video, tracks[kind] != nil, disabledKinds.insert(kind).inserted else { return }
    tracks[kind]?.task?.cancel()
    tracks[kind]?.task = nil
    tracks[kind]?.ended = true
    tracks[kind]?.bufferedEnd = .invalid
    tracks[kind]?.fetchedEnd = .invalid
    renderer.clearVideo()
    resumeAlignmentWaiters()
    clockMayChange()
  }
}
