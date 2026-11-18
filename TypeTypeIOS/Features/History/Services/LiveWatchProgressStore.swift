import SwiftUI

final class LiveWatchProgressStore: ObservableObject {
  @Published private(set) var fractions: [String: Double] = [:]
  var loader: (([String]) async throws -> [String: Int64])?
  private var requested: Set<String> = []

  @MainActor
  func load(_ videos: [LiveVideoItem]) async {
    guard let loader else { return }
    let wanted = videos.filter { $0.duration > 0 && !$0.url.isEmpty && !$0.isLive && !requested.contains($0.url) }
    guard !wanted.isEmpty else { return }
    requested.formUnion(wanted.map(\.url))
    guard let positions = try? await loader(wanted.map(\.url)) else {
      requested.subtract(wanted.map(\.url))
      return
    }
    for video in wanted {
      guard let position = positions[video.url], position > 0, fractions[video.canonicalID] == nil else { continue }
      fractions[video.canonicalID] = min(Double(position) / (Double(video.duration) * 1000), 1)
    }
  }

  func forget() {
    requested = []
  }

  func fraction(forVideoID videoID: String) -> Double? {
    guard !videoID.isEmpty else { return nil }
    return fractions[videoID]
  }

  func seed(fromHistory items: [LiveHistoryItem]) {
    for item in items {
      let fraction = item.progressFraction
      guard fraction > 0 else { continue }
      if !item.url.isEmpty {
        fractions[item.url] = fraction
      }
      if !item.id.isEmpty {
        fractions[item.id] = fraction
      }
    }
  }

  func update(
    videoID: String,
    positionMilliseconds: Int64,
    durationMilliseconds: Int64?
  ) {
    guard !videoID.isEmpty,
      let duration = durationMilliseconds,
      duration > 0
    else { return }
    let fraction = min(
      max(Double(positionMilliseconds) / Double(duration), 0),
      1
    )
    guard fraction > 0 else {
      fractions.removeValue(forKey: videoID)
      return
    }
    fractions[videoID] = fraction
  }
}

struct LiveWatchProgressLoading: ViewModifier {
  let videos: [LiveVideoItem]
  @EnvironmentObject private var watchProgress: LiveWatchProgressStore

  func body(content: Content) -> some View {
    content.task(id: videos.map(\.url)) { await watchProgress.load(videos) }
  }
}

extension View {
  func loadsWatchProgress(_ videos: [LiveVideoItem]) -> some View {
    modifier(LiveWatchProgressLoading(videos: videos))
  }
}
