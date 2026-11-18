import Foundation

// The chat of a past broadcast follows the playback position, as on the web: one page from where the viewer is, the
// next page a little before it runs out, and a fresh page from the new position after a seek outside what is loaded.
struct LiveTwitchVodChatWindow: Equatable {
  enum Request: Equatable {
    case offset(Double)
    case cursor(String)
  }

  static let visible = 150
  static let prefetch: Double = 20
  static let seekGap: Double = 60

  private(set) var comments: [LiveTwitchVideoComment] = []
  private(set) var isLoaded = false
  private var cursor: String?
  private var hasMore = false
  private var from: Double = 0
  private var until: Double = 0

  func request(at seconds: Double) -> Request? {
    if !isLoaded || seconds < from - 1 || seconds > until + Self.seekGap { return .offset(max(0, seconds)) }
    if hasMore, let cursor, seconds > until - Self.prefetch { return .cursor(cursor) }
    return nil
  }

  mutating func apply(_ page: LiveTwitchPage<LiveTwitchVideoComment>, for request: Request, at seconds: Double) {
    let last = page.items.last?.offset
    switch request {
    case .offset:
      comments = page.items
      from = seconds
      until = last ?? seconds
    case .cursor:
      let known = Set(comments.map(\.id))
      comments = Self.trimPlayed(comments + page.items.filter { !known.contains($0.id) }, at: seconds)
      from = comments.first?.offset ?? from
      until = last ?? until
    }
    cursor = page.cursor
    hasMore = page.hasMore
    isLoaded = true
  }

  func visibleComments(at seconds: Double) -> [LiveTwitchVideoComment] {
    Array(comments.filter { $0.offset <= seconds }.suffix(Self.visible))
  }

  // Keeps every comment still ahead and only the last ones already shown: a long broadcast watched to its end would
  // otherwise hold its whole chat in memory.
  static func trimPlayed(_ comments: [LiveTwitchVideoComment], at seconds: Double) -> [LiveTwitchVideoComment] {
    let played = comments.filter { $0.offset <= seconds }.count
    let drop = played - visible
    return drop > 0 ? Array(comments.dropFirst(drop)) : comments
  }
}
