import AVFoundation

extension PlaybackEngine {
  func clockMayChange() {
    if !clockStarted {
      guard !tracks.isEmpty,
        tracks.values.allSatisfy({ $0.bufferedEnd.isValid || $0.ended })
      else {
        return
      }
      startClock()
    }
  }

  private func startClock() {
    clockStarted = true
    renderer.setRate(wantsPlay ? rate : 0, time: startTime)
    Self.log.notice("clock start gen=\(self.generation) at \(self.startTime.seconds) now=\(self.renderer.currentTime.seconds) play=\(self.wantsPlay)")
    emit(.started)
    emit(.state(wantsPlay ? .playing : .paused))
    resumeStartWaiters()
  }
}
