import Foundation

enum DemoPlaybackErrorFormatter {
  static func message(for error: Error?) -> String {
    guard let playbackError = error as NSError? else {
      return "The video could not be loaded."
    }
    let underlying =
      playbackError.userInfo[NSUnderlyingErrorKey] as? NSError
    let code = underlying.map {
      "\($0.domain) \($0.code)"
    } ?? "\(playbackError.domain) \(playbackError.code)"
    return "\(playbackError.localizedDescription) (\(code))"
  }
}
