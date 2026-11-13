import Foundation

// The server answered the request with an error instead of opening the stream.
struct LiveChatRefused: Error, Equatable, Sendable {
  let status: Int
  let retryAfter: TimeInterval?
}

private struct LiveChatStreamClosed: Error {}

protocol LiveChatTransport: Sendable {
  // The bytes of the server's /live-chat stream. A status outside 2xx throws LiveChatRefused.
  func open(videoURL: String) async throws -> AsyncThrowingStream<UInt8, Error>
}

// When to ask again. The backoff and the budget are Android TV's; the 4xx rule and the Retry-After cap follow
// the web client: a refusal that waiting cannot change ends the chat at once.
enum LiveChatRetry {
  enum Decision: Equatable {
    case giveUp
    case retry(after: Duration)
  }

  static let backoff: [Duration] = [.seconds(1), .seconds(2), .seconds(4), .seconds(8), .seconds(15), .seconds(30)]
  static let maximumFailures = 6
  static let longestRetryAfter: TimeInterval = 60

  // `failures` counts the consecutive failures including this one.
  static func decision(afterFailure failures: Int, error: Error) -> Decision {
    guard failures <= maximumFailures else { return .giveUp }
    let step = backoff[min(failures - 1, backoff.count - 1)]
    guard let refused = error as? LiveChatRefused else { return .retry(after: step) }
    switch refused.status {
    case 429:
      guard let seconds = refused.retryAfter, seconds > 0 else { return .retry(after: step) }
      return .retry(after: .seconds(min(seconds, longestRetryAfter)))
    // 401: the access token may have been renewed by another request since the stream was opened.
    case 401, 408, 500...599:
      return .retry(after: step)
    default:
      return .giveUp
    }
  }
}

// One chat stream per call to `events`, ended by cancelling the consumer: that closes the connection, which
// stops the server's session.
final class LiveChatService: Sendable {
  private let transport: LiveChatTransport
  private let pause: @Sendable (Duration) async throws -> Void

  init(
    transport: LiveChatTransport,
    pause: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
  ) {
    self.transport = transport
    self.pause = pause
  }

  func events(videoURL: String) -> AsyncStream<LiveChatEvent> {
    AsyncStream(bufferingPolicy: .bufferingNewest(500)) { continuation in
      let task = Task { await self.run(videoURL, continuation) }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private func run(_ videoURL: String, _ output: AsyncStream<LiveChatEvent>.Continuation) async {
    var failures = 0
    // True once the live is over.
    func handle(_ raw: LiveSSEEvent) throws -> Bool {
      guard let event = try LiveChatEventDecoder.decode(raw) else { return false }
      // A chat that delivers again has recovered: the next drop starts the backoff over.
      if case .message = event { failures = 0 }
      output.yield(event)
      if case .ended = event { return true }
      return false
    }

    while !Task.isCancelled {
      var failure: Error = LiveChatStreamClosed()
      do {
        let bytes = try await transport.open(videoURL: videoURL)
        output.yield(.connected)
        var parser = LiveSSEParser()
        for try await byte in bytes {
          if let raw = parser.feed(byte), try handle(raw) {
            output.finish()
            return
          }
        }
        if let raw = parser.finish(), try handle(raw) {
          output.finish()
          return
        }
      } catch is CancellationError {
        output.finish()
        return
      } catch {
        failure = error
      }
      guard !Task.isCancelled else { break }
      failures += 1
      switch LiveChatRetry.decision(afterFailure: failures, error: failure) {
      case .giveUp:
        output.yield(.unavailable)
        output.finish()
        return
      case let .retry(delay):
        do {
          try await pause(delay)
        } catch {
          output.finish()
          return
        }
      }
    }
    output.finish()
  }
}
