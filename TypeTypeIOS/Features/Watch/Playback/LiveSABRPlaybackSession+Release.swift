import Foundation

extension LiveSABRPlaybackSession {
  func release() async {
    guard !isReleased else { return }
    isReleased = true
    stopMaintenance()
    cancelWindowLoad()
    guard let sessionID = control?.sessionID else { return }
    await service.releaseSABRPlayback(sessionID: sessionID)
  }

  func adopt(_ next: LiveSABRPlaybackControl) {
    let previous = control?.sessionID
    control = next
    guard let previous, previous != next.sessionID else { return }
    Task { [service] in await service.releaseSABRPlayback(sessionID: previous) }
  }

  func discardIfReleased(_ created: LiveSABRPlaybackControl) async throws {
    guard isReleased else { return }
    await service.releaseSABRPlayback(sessionID: created.sessionID)
    throw CancellationError()
  }
}
