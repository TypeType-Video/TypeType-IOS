import Foundation

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
