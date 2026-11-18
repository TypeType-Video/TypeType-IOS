import Foundation

protocol LiveServerEventsTransport: Sendable {
  func openServerEvents() async throws -> AsyncThrowingStream<UInt8, Error>
}

enum LiveServerEvent: Equatable {
  case hello(LiveServerHello)
  case notice(LiveServerNotice)
  case cleared
  case lost
  case reachable
}

// Follows /server/events like the web client: reconnects after 1, 2, 4 then 5 seconds, and stops for good on a 404,
// which is a server without the stream.
final class LiveServerEventsService: Sendable {
  static let longestRetry: Duration = .seconds(5)
  static let helloWait: Duration = .seconds(3)

  private let transport: LiveServerEventsTransport
  private let pause: @Sendable (Duration) async throws -> Void

  init(transport: LiveServerEventsTransport, pause: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
    self.transport = transport
    self.pause = pause
  }

  func events() -> AsyncStream<LiveServerEvent> {
    AsyncStream(bufferingPolicy: .bufferingNewest(50)) { continuation in
      let task = Task { await self.run(continuation) }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private func run(_ output: AsyncStream<LiveServerEvent>.Continuation) async {
    var attempt = 0
    while !Task.isCancelled {
      do {
        let bytes = try await transport.openServerEvents()
        let silence = Task { [pause] in
          guard (try? await pause(Self.helloWait)) != nil else { return }
          output.yield(.reachable)
        }
        defer { silence.cancel() }
        var parser = LiveSSEParser()
        for try await byte in bytes {
          guard let raw = parser.feed(byte), let event = Self.decode(raw) else { continue }
          if case .hello = event {
            silence.cancel()
            attempt = 0
          }
          output.yield(event)
        }
      } catch is CancellationError {
        break
      } catch let refusal as LiveChatRefused where refusal.status == 404 {
        break
      } catch {}
      guard !Task.isCancelled else { break }
      output.yield(.lost)
      let wait = min(Duration.seconds(1 << min(attempt, 4)), Self.longestRetry)
      attempt += 1
      guard (try? await pause(wait)) != nil else { break }
    }
    output.finish()
  }

  static func decode(_ event: LiveSSEEvent) -> LiveServerEvent? {
    if event.name == "clear" { return .cleared }
    let data = Data(event.data.utf8)
    switch event.name {
    case "hello": return (try? JSONDecoder().decode(LiveServerHello.self, from: data)).map { .hello($0) }
    case "notice": return (try? JSONDecoder().decode(LiveServerNotice.self, from: data)).map { .notice($0) }
    default: return nil
    }
  }
}
