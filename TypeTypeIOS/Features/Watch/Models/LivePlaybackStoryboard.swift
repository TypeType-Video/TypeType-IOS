import Foundation

struct LivePlaybackPreviewFrames: Decodable, Hashable {
  let urls: [String]
  let frameWidth: Int
  let frameHeight: Int
  let totalCount: Int
  let durationPerFrame: Int
  let framesPerPageX: Int
  let framesPerPageY: Int
}

struct LivePlaybackStoryboardFrame: Equatable {
  let url: URL
  let column: Int
  let row: Int
  let frameWidth: Int
  let frameHeight: Int
  let columns: Int
  let rows: Int
}

extension LivePlaybackPreviewFrames {
  // Same pick as Android: the smallest set at least 160 px wide, otherwise the widest.
  static func best(_ sets: [LivePlaybackPreviewFrames]) -> LivePlaybackPreviewFrames? {
    let usable = sets.filter { $0.frame(at: 0) != nil }
    return usable.filter { $0.frameWidth >= 160 }.min { $0.frameWidth < $1.frameWidth }
      ?? usable.max { $0.frameWidth < $1.frameWidth }
  }

  func frame(at position: TimeInterval) -> LivePlaybackStoryboardFrame? {
    guard totalCount > 0, durationPerFrame > 0, framesPerPageX > 0, framesPerPageY > 0,
      frameWidth > 0, frameHeight > 0
    else { return nil }
    let pages = urls.filter { !$0.isEmpty }
    guard !pages.isEmpty else { return nil }
    let elapsed = Int(max(position, 0) * 1000) / durationPerFrame
    let index = min(elapsed, totalCount - 1)
    let perPage = framesPerPageX * framesPerPageY
    let page = min(index / perPage, pages.count - 1)
    let inPage = index % perPage
    guard let url = URL(string: pages[page]) else { return nil }
    return LivePlaybackStoryboardFrame(
      url: url, column: inPage % framesPerPageX, row: inPage / framesPerPageX,
      frameWidth: frameWidth, frameHeight: frameHeight, columns: framesPerPageX, rows: framesPerPageY
    )
  }
}
