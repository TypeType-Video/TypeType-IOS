import Foundation

struct LiveCrashReport: Codable, Equatable, Identifiable {
  enum Kind: String, Codable {
    case crash
    case hang
  }

  var id = UUID()
  let kind: Kind
  let date: Date
  let appVersion: String
  let system: String
  let device: String
  let exceptionType: Int?
  let signal: Int?
  let terminationReason: String?
  let hangSeconds: Double?
  let frames: [String]

  var text: String {
    var lines = [
      "TypeType iOS \(kind == .crash ? "crash" : "hang") report",
      "Time: \(date.ISO8601Format())",
      "App: \(appVersion)",
      "System: \(system), \(device)",
    ]
    if let exceptionType {
      lines.append("Exception type: \(exceptionType)")
    }
    if let signal {
      lines.append("Signal: \(signal)")
    }
    if let terminationReason, !terminationReason.isEmpty {
      lines.append("Termination: \(terminationReason)")
    }
    if let hangSeconds {
      lines.append("Hang: \(String(format: "%.1f", hangSeconds)) s")
    }
    lines.append("Stack:")
    lines.append(contentsOf: frames.map { "  \($0)" })
    return lines.joined(separator: "\n")
  }

  static func frames(fromCallStackTree data: Data, limit: Int = 40) -> [String] {
    guard let tree = try? JSONDecoder().decode(CallStackTree.self, from: data) else { return [] }
    let stack = tree.callStacks.first { $0.threadAttributed == true } ?? tree.callStacks.first
    var frames: [String] = []
    var next = stack?.callStackRootFrames.first
    while let frame = next, frames.count < limit {
      frames.append("\(frame.binaryName ?? "?") +\(frame.offsetIntoBinaryTextSegment ?? 0)")
      next = frame.subFrames?.first
    }
    return frames
  }

  private struct CallStackTree: Decodable {
    let callStacks: [CallStack]
  }

  private struct CallStack: Decodable {
    let threadAttributed: Bool?
    let callStackRootFrames: [Frame]
  }

  private struct Frame: Decodable {
    let binaryName: String?
    let offsetIntoBinaryTextSegment: Int?
    let subFrames: [Frame]?
  }
}
