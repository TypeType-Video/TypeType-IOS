import CoreGraphics
import Foundation

struct LiveYouTubeSessionStatus: Decodable, Equatable {
  let status: String
  let updatedAt: Int64
  let lastUsedAt: Int64

  var isConnected: Bool { status == "connected" }
}

struct LiveYouTubeBrowserSession: Decodable, Equatable {
  let sessionId: String
  let wsUrl: String
  let expiresAt: Int64
}

enum LiveYouTubeBrowserPhase: String, Equatable {
  case idle
  case connecting
  case opening
  case awaitingLogin = "awaiting_login"
  case capturingSession = "capturing_session"
  case connected
  case closed
  case error

  var isFinished: Bool { self == .connected || self == .closed || self == .error }
}

enum LiveYouTubeBrowserMessage: Equatable {
  case phase(LiveYouTubeBrowserPhase)
  case failure(String)

  init?(text: String) {
    guard text.count <= 16_384,
      let data = text.data(using: .utf8),
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let type = object["type"] as? String
    else { return nil }
    switch type {
    case "status":
      guard let phase = (object["phase"] as? String).flatMap(LiveYouTubeBrowserPhase.init(rawValue:)) else {
        return nil
      }
      self = .phase(phase)
    case "error":
      guard let message = object["message"] as? String else { return nil }
      self = .failure(message)
    default:
      return nil
    }
  }
}

enum LiveYouTubeBrowserInput: Equatable {
  case resize(width: Int, height: Int)
  case tap(x: Int, y: Int)
  case wheel(deltaX: Double, deltaY: Double)
  case key(String)
  case text(String)
  case cancel

  var messages: [[String: Any]] {
    switch self {
    case let .resize(width, height):
      [["type": "resize", "width": width, "height": height]]
    case let .tap(x, y):
      ["down", "up"].map { ["type": "pointer", "event": $0, "x": x, "y": y, "button": "left"] }
    case let .wheel(deltaX, deltaY):
      [["type": "wheel", "deltaX": deltaX, "deltaY": deltaY]]
    case let .key(name):
      ["down", "up"].map { ["type": "key", "event": $0, "key": name, "code": name, "modifiers": [String]()] }
    case let .text(value):
      [["type": "text", "value": value]]
    case .cancel:
      [["type": "cancel"]]
    }
  }

  static func edit(from previous: String, to next: String) -> [LiveYouTubeBrowserInput] {
    let shared = zip(previous, next).prefix { $0 == $1 }.count
    let deletions = Array(repeating: LiveYouTubeBrowserInput.key("Backspace"), count: previous.count - shared)
    let inserted = String(next.dropFirst(shared))
    return deletions + (inserted.isEmpty ? [] : [.text(inserted)])
  }

  static func point(_ location: CGPoint, in container: CGSize, frame: CGSize) -> (x: Int, y: Int)? {
    guard frame.width > 0, frame.height > 0, container.width > 0, container.height > 0 else { return nil }
    let scale = min(container.width / frame.width, container.height / frame.height)
    let offsetX = (container.width - frame.width * scale) / 2
    let offsetY = (container.height - frame.height * scale) / 2
    let x = Int(((location.x - offsetX) / scale).rounded())
    let y = Int(((location.y - offsetY) / scale).rounded())
    return (min(max(x, 0), Int(frame.width) - 1), min(max(y, 0), Int(frame.height) - 1))
  }
}
