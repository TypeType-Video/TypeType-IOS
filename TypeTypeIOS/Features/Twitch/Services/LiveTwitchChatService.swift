import Foundation

protocol LiveTwitchChatTransport: Sendable {
  func openTwitchChat(login: String) async throws -> AsyncThrowingStream<UInt8, Error>
}

enum LiveTwitchChatUpdate: Equatable {
  case connected
  case event(LiveTwitchChatEvent)
  case reconnecting
}

// One event stream per channel, ended by cancelling its consumer. Like the web client it reconnects for as long as the
// chat is open, waiting twice as long after each drop up to 30 seconds, and starts over after a minute connected.
final class LiveTwitchChatService: Sendable {
  static let longestBackoff: Duration = .seconds(30)
  static let stableConnection: TimeInterval = 60

  private let transport: LiveTwitchChatTransport
  private let pause: @Sendable (Duration) async throws -> Void

  init(transport: LiveTwitchChatTransport, pause: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
    self.transport = transport
    self.pause = pause
  }

  func updates(login: String) -> AsyncStream<LiveTwitchChatUpdate> {
    AsyncStream(bufferingPolicy: .bufferingNewest(500)) { continuation in
      let task = Task { await self.run(login, continuation) }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private func run(_ login: String, _ output: AsyncStream<LiveTwitchChatUpdate>.Continuation) async {
    var backoff: Duration = .seconds(1)
    let decoder = JSONDecoder()
    while !Task.isCancelled {
      let started = Date()
      do {
        let bytes = try await transport.openTwitchChat(login: login)
        output.yield(.connected)
        var parser = LiveSSEParser()
        for try await byte in bytes {
          guard let raw = parser.feed(byte), let data = raw.data.data(using: .utf8),
            let event = try? decoder.decode(LiveTwitchChatEvent.self, from: data)
          else { continue }
          output.yield(.event(event))
        }
      } catch is CancellationError {
        break
      } catch {}
      guard !Task.isCancelled else { break }
      output.yield(.reconnecting)
      if Date().timeIntervalSince(started) > Self.stableConnection { backoff = .seconds(1) }
      do {
        try await pause(backoff)
      } catch {
        break
      }
      backoff = min(backoff * 2, Self.longestBackoff)
    }
    output.finish()
  }
}
