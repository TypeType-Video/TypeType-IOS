import Foundation
import TypeTypePlayerKit

// Immutable; the playback service already serves concurrent loads.
final class LiveProviderSegmentSource: MediaSegmentSource, @unchecked Sendable {
  struct Track: Sendable {
    let url: URL
    let initRange: ClosedRange<Int>
    let indexRange: ClosedRange<Int>
  }

  let trackKinds: [MP4TrackKind]
  private let tracks: [MP4TrackKind: Track]
  private let loader: LiveProviderRangeLoader
  private let indexes: LiveProviderSegmentIndexes

  init?(preparation: LivePlaybackPreparation, service: LivePlaybackServiceProtocol) {
    guard case let .separateProgressive(videoURL, audioURL)? = preparation.providerPlayback,
      let video = preparation.video.flatMap({ Self.track(videoURL, $0.initStart, $0.initEnd, $0.indexStart, $0.indexEnd) }),
      let audio = preparation.audio.flatMap({ Self.track(audioURL, $0.initStart, $0.initEnd, $0.indexStart, $0.indexEnd) })
    else {
      return nil
    }
    let loader = LiveProviderRangeLoader(service: service)
    let tracks: [MP4TrackKind: Track] = preparation.audioOnly ? [.audio: audio] : [.video: video, .audio: audio]
    self.tracks = tracks
    self.loader = loader
    trackKinds = preparation.audioOnly ? [.audio] : [.video, .audio]
    indexes = LiveProviderSegmentIndexes(kinds: Array(tracks.keys)) { kind in
      guard let track = tracks[kind] else { throw LivePlaybackFailure.invalidPlaylist }
      let data = try await loader.load(track.url, range: track.indexRange)
      return try MP4SegmentIndex.entries(in: data, fileOffset: Int64(track.indexRange.lowerBound))
    }
  }

  func initSegment(for kind: MP4TrackKind) async throws -> Data {
    let track = try track(kind)
    return try await loader.load(track.url, range: track.initRange)
  }

  func firstSequence(for kind: MP4TrackKind, at time: TimeInterval) async throws -> Int {
    let entries = try await entries(kind)
    return entries.lastIndex { $0.startTime <= time } ?? 0
  }

  func segment(for kind: MP4TrackKind, sequence: Int) async throws -> Data? {
    let entries = try await entries(kind)
    guard entries.indices.contains(sequence) else { return nil }
    let range = entries[sequence].byteRange
    guard range.lowerBound >= 0, range.upperBound <= Int64(Int.max), !range.isEmpty else {
      throw LivePlaybackFailure.invalidPlaylist
    }
    return try await loader.load(try track(kind).url, range: Int(range.lowerBound)...Int(range.upperBound - 1))
  }

  private func track(_ kind: MP4TrackKind) throws -> Track {
    guard let track = tracks[kind] else { throw LivePlaybackFailure.invalidPlaylist }
    return track
  }

  private func entries(_ kind: MP4TrackKind) async throws -> [MP4IndexEntry] {
    try await indexes.entries(kind)
  }

  private static func track(
    _ url: URL,
    _ initStart: Int64,
    _ initEnd: Int64,
    _ indexStart: Int64,
    _ indexEnd: Int64
  ) -> Track? {
    guard initStart >= 0, initEnd >= initStart, indexStart > initEnd, indexEnd >= indexStart,
      indexEnd <= Int64(Int.max)
    else {
      return nil
    }
    return Track(
      url: url,
      initRange: Int(initStart)...Int(initEnd),
      indexRange: Int(indexStart)...Int(indexEnd)
    )
  }
}
