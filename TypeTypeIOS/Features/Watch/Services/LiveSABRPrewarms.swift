import Foundation

/// Client side of the server's prewarm handoff: the server keeps a prewarmed
/// session for 60 s and hands it to a create with the same user, video,
/// formats, and start. A create waits for a prewarm of the same request still
/// in flight, and a prewarm arriving after the create is dropped, so one start
/// never opens two sessions at the provider.
actor LiveSABRPrewarms {
  struct Key: Hashable {
    let videoID: String
    let videoItag: Int
    let audioItag: Int
    let audioTrackID: String?
    let startTimeMS: Int64
    let audioOnly: Bool
    let isLive: Bool

    init(videoID: String, request: LiveSABRPlaybackRequest) {
      self.videoID = videoID
      videoItag = request.videoItag
      audioItag = request.audioItag
      audioTrackID = request.audioTrackID
      startTimeMS = request.startTimeMS
      audioOnly = request.audioOnly
      isLive = request.isLive
    }
  }

  /// Under the server's 60 s so a handoff is never assumed after it expired.
  static let lifetime: Duration = .seconds(50)
  private var inFlight: [Key: Task<Void, Never>] = [:]
  private var settled: [Key: ContinuousClock.Instant] = [:]

  func prewarm(_ key: Key, send: @escaping @Sendable () async -> Void) async {
    prune()
    guard inFlight[key] == nil, settled[key] == nil else { return }
    let task = Task(priority: .userInitiated) { await send() }
    inFlight[key] = task
    await task.value
    inFlight[key] = nil
    settled[key] = .now
  }

  /// Runs right before a real create of `key`.
  func settle(_ key: Key) async {
    if let task = inFlight[key] {
      await task.value
    }
    settled[key] = .now
  }

  private func prune() {
    let now = ContinuousClock.now
    settled = settled.filter { now - $0.value < Self.lifetime }
  }
}
