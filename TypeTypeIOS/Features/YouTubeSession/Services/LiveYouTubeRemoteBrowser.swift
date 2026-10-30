import UIKit

@MainActor
final class LiveYouTubeRemoteBrowser: ObservableObject {
  @Published private(set) var phase = LiveYouTubeBrowserPhase.connecting
  @Published private(set) var frame: UIImage?
  @Published private(set) var errorMessage: String?

  private var socket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?

  func connect(url: URL, accessToken: String?) {
    var request = URLRequest(url: url)
    if let accessToken {
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }
    let socket = URLSession.shared.webSocketTask(with: request)
    socket.maximumMessageSize = 8 * 1_024 * 1_024
    self.socket = socket
    socket.resume()
    receiveTask = Task { [weak self] in
      await self?.receive(from: socket)
    }
  }

  func send(_ input: LiveYouTubeBrowserInput) {
    guard let socket, !phase.isFinished else { return }
    for message in input.messages {
      guard let data = try? JSONSerialization.data(withJSONObject: message),
        let text = String(data: data, encoding: .utf8)
      else { continue }
      socket.send(.string(text)) { error in
        if let error {
          AppLogger.app.failure("Sending to the YouTube sign-in browser", error)
        }
      }
    }
  }

  func close() {
    receiveTask?.cancel()
    socket?.cancel(with: .normalClosure, reason: nil)
    socket = nil
    if !phase.isFinished {
      phase = .closed
    }
  }

  private func receive(from socket: URLSessionWebSocketTask) async {
    while !Task.isCancelled {
      let message: URLSessionWebSocketTask.Message
      do {
        message = try await socket.receive()
      } catch {
        if !phase.isFinished {
          phase = .error
          errorMessage = String(localized: "The sign-in browser closed unexpectedly.")
        }
        return
      }
      switch message {
      case let .string(text):
        handle(text)
      case let .data(data):
        let image = await Task.detached(priority: .userInitiated) {
          UIImage(data: data)?.preparingForDisplay()
        }.value
        if let image {
          frame = image
        }
      @unknown default:
        break
      }
    }
  }

  private func handle(_ text: String) {
    switch LiveYouTubeBrowserMessage(text: text) {
    case let .phase(next):
      phase = next
    case let .failure(message):
      phase = .error
      errorMessage = message
    case nil:
      break
    }
  }
}
