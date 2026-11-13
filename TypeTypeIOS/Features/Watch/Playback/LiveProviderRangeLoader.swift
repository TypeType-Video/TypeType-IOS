import Foundation

// The instance relays provider bytes slowly per connection: ranges load as parallel chunks.
struct LiveProviderRangeLoader {
  static let chunkByteCount = 128 * 1_024
  static let minimumRetryByteCount = 16 * 1_024
  static let concurrentChunkLimit = 6

  let service: LivePlaybackServiceProtocol

  func load(
    _ url: URL,
    range: ClosedRange<Int>,
    allowsAdaptiveRetry: Bool = true
  ) async throws -> Data {
    let chunks = Self.chunkRanges(range)
    return try await withThrowingTaskGroup(
      of: (Int, Data).self,
      returning: Data.self
    ) { group in
      var nextIndex = 0
      let initialRequestCount = min(
        chunks.count,
        Self.concurrentChunkLimit
      )
      for _ in 0..<initialRequestCount {
        let index = nextIndex
        let chunk = chunks[index]
        nextIndex += 1
        group.addTask { [self] in
          try await loadChunk(
            url,
            range: chunk,
            index: index,
            allowsAdaptiveRetry: allowsAdaptiveRetry
          )
        }
      }

      var result = Data(
        count: range.upperBound - range.lowerBound + 1
      )
      var completedCount = 0
      while let (index, data) = try await group.next() {
        let chunk = chunks[index]
        let destinationStart = chunk.lowerBound - range.lowerBound
        let destinationEnd = destinationStart + data.count
        guard destinationStart >= 0,
          destinationEnd <= result.count
        else {
          throw LivePlaybackFailure.invalidPlaylist
        }
        result.replaceSubrange(
          destinationStart..<destinationEnd,
          with: data
        )
        completedCount += 1
        guard nextIndex < chunks.count else { continue }
        let queuedIndex = nextIndex
        let queuedChunk = chunks[queuedIndex]
        nextIndex += 1
        group.addTask { [self] in
          try await loadChunk(
            url,
            range: queuedChunk,
            index: queuedIndex,
            allowsAdaptiveRetry: allowsAdaptiveRetry
          )
        }
      }

      guard completedCount == chunks.count else {
        throw LivePlaybackFailure.invalidPlaylist
      }
      return result
    }
  }

  private func loadChunk(
    _ url: URL,
    range: ClosedRange<Int>,
    index: Int,
    allowsAdaptiveRetry: Bool
  ) async throws -> (Int, Data) {
    try Task.checkCancellation()
    let data = try await loadChunkData(
      url,
      range: range,
      allowsAdaptiveRetry: allowsAdaptiveRetry
    )
    let expectedCount = range.upperBound - range.lowerBound + 1
    guard data.count == expectedCount else {
      throw LivePlaybackFailure.invalidPlaylist
    }
    return (index, data)
  }

  private func loadChunkData(
    _ url: URL,
    range: ClosedRange<Int>,
    allowsAdaptiveRetry: Bool
  ) async throws -> Data {
    do {
      return try await service.resourceData(
        for: url,
        range: range
      )
    } catch {
      guard allowsAdaptiveRetry,
        shouldSplit(range, after: error)
      else {
        throw error
      }
      let midpoint = range.lowerBound
        + (range.upperBound - range.lowerBound) / 2
      let lowerRange = range.lowerBound...midpoint
      let upperRange = (midpoint + 1)...range.upperBound
      AppLogger.app.info(
        "Retrying truncated provider bytes \(range.lowerBound, privacy: .public)-\(range.upperBound, privacy: .public) as smaller ranges."
      )
      async let lowerData = loadChunkData(
        url,
        range: lowerRange,
        allowsAdaptiveRetry: true
      )
      async let upperData = loadChunkData(
        url,
        range: upperRange,
        allowsAdaptiveRetry: true
      )
      var result = try await lowerData
      result.append(try await upperData)
      return result
    }
  }

  private func shouldSplit(
    _ range: ClosedRange<Int>,
    after error: Error
  ) -> Bool {
    guard range.upperBound - range.lowerBound + 1
      > Self.minimumRetryByteCount,
      case let NetworkError.statusCode(code, message, _) = error,
      code == 422
    else {
      return false
    }
    return message?.localizedCaseInsensitiveContains(
      "unexpected end of stream"
    ) == true
  }

  static func chunkRanges(
    _ range: ClosedRange<Int>
  ) -> [ClosedRange<Int>] {
    var chunks: [ClosedRange<Int>] = []
    var lowerBound = range.lowerBound
    while lowerBound <= range.upperBound {
      let available = range.upperBound - lowerBound
      let upperBound = lowerBound
        + min(chunkByteCount - 1, available)
      chunks.append(lowerBound...upperBound)
      guard upperBound < range.upperBound else { break }
      lowerBound = upperBound + 1
    }
    return chunks
  }
}
