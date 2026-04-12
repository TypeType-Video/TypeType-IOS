import Foundation

enum BlockedFilter {
  static func apply(to videos: [HomeVideoItem], blockedChannels: Set<String>, blockedVideos: Set<String>) -> [HomeVideoItem] {
    videos.filter { video in
      if blockedVideos.contains(video.url) || blockedVideos.contains(video.id) {
        return false
      }
      return !blockedChannels.contains(video.uploaderUrl)
    }
  }
}
