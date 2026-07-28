import Foundation

enum LiveSABRResourceValidator {
  static func validate(
    _ url: URL,
    sessionID: String,
    generation: Int64,
    itag: Int,
    initialization: Bool
  ) throws {
    guard let components = URLComponents(
      url: url,
      resolvingAgainstBaseURL: false
    ) else {
      throw LivePlaybackFailure.invalidServerResource
    }
    let path = components.path.split(separator: "/").map(String.init)
    let suffix: [String]
    if initialization {
      suffix = [
        "sabr", "playback", sessionID, String(itag), "init"
      ]
    } else {
      guard let sequence = path.last.flatMap(Int64.init),
        sequence >= 0
      else {
        throw LivePlaybackFailure.invalidSABRContract
      }
      suffix = [
        "sabr", "playback", sessionID, String(itag),
        "segment", String(sequence)
      ]
    }
    guard path.suffix(suffix.count).elementsEqual(suffix) else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    let items = components.queryItems ?? []
    guard items.allSatisfy({
      $0.name == "session" || $0.name == "generation"
    }) else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    let generations = items.filter { $0.name == "generation" }
    guard generations.count == 1,
      generations[0].value == String(generation)
    else {
      throw LivePlaybackFailure.invalidSABRContract
    }
  }
}
