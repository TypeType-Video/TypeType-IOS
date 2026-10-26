import Foundation

public protocol MediaSegmentSource: AnyObject, Sendable {
  var trackKinds: [MP4TrackKind] { get }
  func initSegment(for kind: MP4TrackKind) async throws -> Data
  func firstSequence(for kind: MP4TrackKind, at time: TimeInterval) async throws -> Int
  /// Nil once the track has no further segment.
  func segment(for kind: MP4TrackKind, sequence: Int) async throws -> Data?
}

public enum TypeTypePlayerState: Equatable, Sendable {
  case idle
  case buffering
  case playing
  case paused
  case ended
  case failed(String)
}

public struct TypeTypePlayerConfiguration: Sendable {
  public var forwardBuffer: TimeInterval
  public var resumeBuffer: TimeInterval
  public var retryWindow: Duration

  public init(forwardBuffer: TimeInterval = 30, resumeBuffer: TimeInterval = 1, retryWindow: Duration = .seconds(120)) {
    self.forwardBuffer = forwardBuffer
    self.resumeBuffer = resumeBuffer
    self.retryWindow = retryWindow
  }
}
