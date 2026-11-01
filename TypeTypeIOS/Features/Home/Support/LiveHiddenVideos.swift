import SwiftUI

// The server leaves blocked videos and channels out of its next answers; lists already on screen drop them here.
@MainActor
final class LiveHiddenVideos: ObservableObject {
  @Published private(set) var videoURLs: Set<String> = []
  @Published private(set) var channelURLs: Set<String> = []

  func hides(_ video: LiveVideoItem) -> Bool {
    videoURLs.contains(video.url)
      || (!video.uploaderURL.isEmpty && channelURLs.contains(video.uploaderURL))
  }

  func visible(_ videos: [LiveVideoItem]) -> [LiveVideoItem] {
    guard !videoURLs.isEmpty || !channelURLs.isEmpty else { return videos }
    return videos.filter { !hides($0) }
  }

  func hide(_ kind: LiveContentControlKind, url: String) {
    switch kind {
    case .blockedVideos: videoURLs.insert(url)
    case .blockedChannels: channelURLs.insert(url)
    case .blockedKeywords, .allowedChannels: return
    }
  }

  func show(_ kind: LiveContentControlKind, url: String) {
    switch kind {
    case .blockedVideos: videoURLs.remove(url)
    case .blockedChannels: channelURLs.remove(url)
    case .blockedKeywords, .allowedChannels: return
    }
  }

  func clear() {
    videoURLs = []
    channelURLs = []
  }
}

struct LiveHiddenVideosReader<Content: View>: View {
  @ObservedObject var hidden: LiveHiddenVideos
  @ViewBuilder let content: (LiveHiddenVideos) -> Content

  init(_ hidden: LiveHiddenVideos, @ViewBuilder content: @escaping (LiveHiddenVideos) -> Content) {
    self.hidden = hidden
    self.content = content
  }

  var body: some View {
    content(hidden)
  }
}
