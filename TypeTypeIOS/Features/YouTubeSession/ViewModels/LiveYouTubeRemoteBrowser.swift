import Foundation
import UIKit

@MainActor
final class LiveYouTubeRemoteBrowser: ObservableObject {
  @Published private(set) var phase = LiveYouTubeRemotePhase.idle
  @Published private(set) var frame: UIImage?
  @Published private(set) var errorMessage: String?

  private var socket: URLSessionWebSocketTask?
  private var receiver: Task<Void, Never>?

  func connect(to url: URL) {
    close()
    phase = .connecting
    errorMessage = nil
    let socket = URLSession.shared.webSocketTask(with: url)
    self.socket = socket
    socket.resume()
    receiver = Task { [weak self] in
      await self?.receiveMessages()
    }
  }

  func close() {
    receiver?.cancel()
    receiver = nil
    socket?.cancel(with: .goingAway, reason: nil)
    socket = nil
    frame = nil
    if phase != .connected {
      phase = .idle
    }
  }

  func sendResize(width: Int, height: Int) {
    send([
      "type": "resize",
      "width": max(width, 1),
      "height": max(height, 1),
    ])
  }

  func sendPointer(
    event: String,
    x: Int,
    y: Int
  ) {
    send([
      "type": "pointer",
      "event": event,
      "x": max(x, 0),
      "y": max(y, 0),
      "button": "left",
    ])
  }

  func sendWheel(deltaY: Int) {
    send([
      "type": "wheel",
      "deltaX": 0,
      "deltaY": deltaY,
    ])
  }

  func sendText(_ value: String) {
    guard !value.isEmpty else { return }
    send(["type": "text", "value": value])
  }

  func sendKey(_ key: String, code: String) {
    send([
      "type": "key",
      "event": "down",
      "key": key,
      "code": code,
      "modifiers": [],
    ])
    send([
      "type": "key",
      "event": "up",
      "key": key,
      "code": code,
      "modifiers": [],
    ])
  }

  func sendCancel() {
    send(["type": "cancel"])
  }

  private func receiveMessages() async {
    guard let socket else { return }
    do {
      while !Task.isCancelled {
        let message = try await socket.receive()
        switch message {
        case let .data(data):
          if let image = UIImage(data: data) {
            frame = image
          }
        case let .string(text):
          consume(text)
        @unknown default:
          continue
        }
      }
    } catch is CancellationError {
      return
    } catch {
      guard !Task.isCancelled else { return }
      phase = .error
      errorMessage = "Remote browser connection failed."
    }
  }

  private func consume(_ text: String) {
    guard let data = text.data(using: .utf8),
      let object = try? JSONSerialization.jsonObject(with: data)
        as? [String: Any],
      let type = object["type"] as? String
    else {
      return
    }
    if type == "status",
      let rawPhase = object["phase"] as? String,
      let next = LiveYouTubeRemotePhase(rawValue: rawPhase) {
      phase = next
    } else if type == "error" {
      phase = .error
      errorMessage = object["message"] as? String
        ?? "The remote browser reported an error."
    }
  }

  private func send(_ object: [String: Any]) {
    guard let socket,
      let data = try? JSONSerialization.data(withJSONObject: object),
      let text = String(data: data, encoding: .utf8)
    else {
      return
    }
    socket.send(.string(text)) { [weak self] error in
      guard error != nil else { return }
      Task { @MainActor in
        self?.phase = .error
        self?.errorMessage = "Could not send remote browser input."
      }
    }
  }
}
