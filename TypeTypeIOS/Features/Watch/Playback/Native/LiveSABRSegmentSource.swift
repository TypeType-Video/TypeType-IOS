import Foundation
import TypeTypePlayerKit

// Immutable; the playback service already serves concurrent loads.
final class LiveSABRSegmentSource: MediaSegmentSource, @unchecked Sendable {
  let trackKinds: [MP4TrackKind]
  private let session: LiveSABRPlaybackSession
  private let service: LivePlaybackServiceProtocol

  init(session: LiveSABRPlaybackSession, service: LivePlaybackServiceProtocol, audioOnly: Bool) {
    self.session = session
    self.service = service
    trackKinds = audioOnly ? [.audio] : [.video, .audio]
  }

  func initSegment(for kind: MP4TrackKind) async throws -> Data {
    let track = try Self.track(kind, in: try await session.snapshot())
    return try await LiveSABRPendingResource.load(track.initURL, service: service)
  }

  // Segments are numbered from the start of the video and the server repositions its pump on
  // demand: a start outside the known window is estimated, and the engine corrects it.
  func firstSequence(for kind: MP4TrackKind, at time: TimeInterval) async throws -> Int {
    let snapshot = try await session.snapshot()
    let targetMS = Int64(max(time, 0) * 1_000)
    let segments = try Self.track(kind, in: snapshot).segments
    if let known = segments.last(where: { $0.startMS <= targetMS && targetMS < $0.startMS + $0.durationMS }) {
      return known.sequence
    }
    guard let end = Self.endSegment(kind, in: snapshot), snapshot.durationMS > 0 else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    let averageMS = Double(snapshot.durationMS) / Double(end)
    return min(max(Int(Double(targetMS) / averageMS) + 1, 1), Int(end))
  }

  func segment(for kind: MP4TrackKind, sequence: Int) async throws -> Data? {
    let snapshot = try await session.snapshot()
    if let end = Self.endSegment(kind, in: snapshot), sequence > end {
      return nil
    }
    guard let url = try Self.track(kind, in: snapshot).mediaURL(sequence: sequence) else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    return try await LiveSABRPendingResource.load(url, service: service)
  }

  private static func endSegment(_ kind: MP4TrackKind, in snapshot: LiveSABRPlaybackSnapshot) -> Int? {
    let end = kind == .video ? snapshot.index?.tracks.video.endSegment : snapshot.index?.tracks.audio.endSegment
    guard let end, end > 0, end <= Int64(Int.max) else { return nil }
    return Int(end)
  }

  private static func track(
    _ kind: MP4TrackKind,
    in snapshot: LiveSABRPlaybackSnapshot
  ) throws -> LiveSABRTrackSnapshot {
    switch kind {
    case .audio:
      return snapshot.audio
    case .video:
      guard let video = snapshot.video else { throw LivePlaybackFailure.invalidSABRContract }
      return video
    }
  }
}
