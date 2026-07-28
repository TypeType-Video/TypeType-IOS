import Foundation

struct LivePlaybackScope: Codable, Equatable, Hashable {
  let serverID: String
  let accountID: String
}

enum LivePlaybackRepeatMode: String, Codable, CaseIterable {
  case off
  case all
  case one

  var next: LivePlaybackRepeatMode {
    switch self {
    case .off: return .all
    case .all: return .one
    case .one: return .off
    }
  }

  var title: String {
    switch self {
    case .off: return "Repeat off"
    case .all: return "Repeat all"
    case .one: return "Repeat one"
    }
  }

  var symbol: String {
    self == .one ? "repeat.1" : "repeat"
  }
}

struct LivePlaybackQueueSnapshot: Codable, Equatable {
  var title: String
  var videos: [LiveVideoItem]
  var currentIndex: Int
  var repeatMode: LivePlaybackRepeatMode
  var updatedAt: Date

  static let empty = LivePlaybackQueueSnapshot(
    title: "",
    videos: [],
    currentIndex: -1,
    repeatMode: .off,
    updatedAt: .distantPast
  )

  var isActive: Bool {
    currentIndex >= 0 && currentIndex < videos.count
  }

  var current: LiveVideoItem? {
    guard isActive else { return nil }
    return videos[currentIndex]
  }

  var nextIndex: Int? {
    guard isActive else { return nil }
    if currentIndex + 1 < videos.count {
      return currentIndex + 1
    }
    if repeatMode == .all, videos.count > 1 {
      return 0
    }
    return nil
  }

  var next: LiveVideoItem? {
    guard let nextIndex else { return nil }
    return videos[nextIndex]
  }

  mutating func enqueue(
    _ video: LiveVideoItem,
    current currentVideo: LiveVideoItem,
    playNext: Bool
  ) -> LivePlaybackQueueMutationResult {
    if video.url == currentVideo.url {
      return .alreadyPlaying
    }
    if !isActive {
      self = LivePlaybackQueueSnapshot(
        title: "Playback queue",
        videos: [currentVideo],
        currentIndex: 0,
        repeatMode: .off,
        updatedAt: .now
      )
    }
    if let existing = videos.firstIndex(
      where: { $0.url == video.url }
    ) {
      guard playNext, existing != currentIndex + 1 else {
        return .alreadyQueued
      }
      moveNext(index: existing)
      return .moved
    }
    let insertion = playNext
      ? min(currentIndex + 1, videos.count)
      : videos.count
    videos.insert(video, at: insertion)
    updatedAt = .now
    return .added
  }

  mutating func moveNext(index: Int) {
    guard isActive,
      videos.indices.contains(index),
      index != currentIndex,
      index != currentIndex + 1,
      let currentURL = current?.url
    else {
      return
    }
    let moved = videos.remove(at: index)
    currentIndex = videos.firstIndex { $0.url == currentURL }
      ?? currentIndex
    videos.insert(moved, at: min(currentIndex + 1, videos.count))
    updatedAt = .now
  }

  mutating func remove(index: Int) {
    guard isActive,
      videos.indices.contains(index),
      index != currentIndex,
      let currentURL = current?.url
    else {
      return
    }
    videos.remove(at: index)
    currentIndex = videos.firstIndex { $0.url == currentURL } ?? 0
    updatedAt = .now
  }

  mutating func shuffleUpcoming() {
    guard isActive else { return }
    let start = currentIndex + 1
    guard videos.count - start > 1 else { return }
    videos.replaceSubrange(start..., with: videos[start...].shuffled())
    updatedAt = .now
  }
}

enum LivePlaybackQueueMutationResult: Equatable {
  case added
  case moved
  case alreadyQueued
  case alreadyPlaying
  case noActivePlayback
  case invalidVideo
}
