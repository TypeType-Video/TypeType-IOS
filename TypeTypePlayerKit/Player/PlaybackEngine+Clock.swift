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
    } else if stalled, hasResumeBuffer() {
      stalled = false
      if wantsPlay {
        renderer.setRate(rate)
        emit(.state(.playing))
      } else {
        emit(.state(.paused))
      }
    }
    watch()
  }

  private func startClock() {
    clockStarted = true
    renderer.setRate(wantsPlay ? rate : 0, time: startTime)
    Self.log.notice("clock start gen=\(self.generation) at \(self.startTime.seconds) now=\(self.renderer.currentTime.seconds) play=\(self.wantsPlay)")
    emit(.started)
    emit(.state(wantsPlay ? .playing : .paused))
    resumeStartWaiters()
  }

  private func hasResumeBuffer() -> Bool {
    let now = renderer.currentTime
    let needed = CMTime(seconds: configuration.resumeBuffer, preferredTimescale: 600)
    return tracks.values.allSatisfy { track in
      track.ended || (track.bufferedEnd.isValid && track.bufferedEnd - now >= needed)
    }
  }

  private func watch() {
    watchTask?.cancel()
    let current = generation
    let pending = tracks.values.filter { !$0.ended }
    let renderer = renderer
    if pending.isEmpty {
      let end = tracks.values.map(\.bufferedEnd).filter(\.isValid).max() ?? renderer.currentTime
      watchTask = Task {
        await renderer.waitUntil(end)
        guard !Task.isCancelled else { return }
        self.reachedEnd(generation: current)
      }
    } else if let low = pending.map(\.bufferedEnd).filter(\.isValid).min() {
      watchTask = Task {
        await renderer.waitUntil(low - CMTime(value: 1, timescale: 20))
        guard !Task.isCancelled else { return }
        self.reachedLowWater(generation: current)
      }
    }
  }

  private func reachedLowWater(generation current: Int) {
    guard current == generation, clockStarted, !stalled, !ended, wantsPlay else { return }
    let now = renderer.currentTime
    let margin = CMTime(value: 1, timescale: 20)
    let starving = tracks.values.contains { !$0.ended && $0.bufferedEnd - now <= margin }
    guard starving else {
      watch()
      return
    }
    stalled = true
    Self.log.notice("stalled gen=\(self.generation) start=\(self.startTime.seconds) at \(now.seconds) video=\(self.tracks[.video]?.bufferedEnd.seconds ?? -1) audio=\(self.tracks[.audio]?.bufferedEnd.seconds ?? -1)")
    renderer.setRate(0)
    emit(.state(.buffering))
  }

  private func reachedEnd(generation current: Int) {
    guard current == generation, clockStarted, !ended else { return }
    ended = true
    renderer.setRate(0)
    emit(.state(.ended))
  }
}
