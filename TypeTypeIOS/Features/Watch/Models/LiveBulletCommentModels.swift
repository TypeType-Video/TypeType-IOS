import Combine
import Foundation

struct LiveBulletComment: Decodable, Equatable {
  let text: String
  let argbColor: Int
  let position: String
  let relativeFontSize: Double
  let durationMilliseconds: Int64
  let isLive: Bool

  private enum CodingKeys: String, CodingKey {
    case text, argbColor, position, relativeFontSize, isLive
    case durationMilliseconds = "durationMs"
  }
}

struct LiveBulletCommentsPage: Decodable {
  let comments: [LiveBulletComment]
  let nextpage: String?
}

struct LiveBulletCommentState: Equatable {
  var comments: [LiveBulletComment] = []
  var isLoading = false

  static let empty = LiveBulletCommentState()

  static let loading = LiveBulletCommentState(
    comments: [],
    isLoading: true
  )
}

@MainActor
final class LiveBulletCommentStore: ObservableObject {
  @Published private(set) var state = LiveBulletCommentState.empty

  func update(_ state: LiveBulletCommentState) {
    guard self.state != state else { return }
    self.state = state
  }
}
