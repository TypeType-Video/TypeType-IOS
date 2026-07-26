enum LiveSearchResult: Hashable, Identifiable {
  case channel(LiveChannelResult)
  case playlist(LivePlaylistResult)
  case video(LiveVideoItem)

  var id: String {
    switch self {
    case let .channel(channel):
      return "channel:\(channel.canonicalID)"
    case let .playlist(playlist):
      return "playlist:\(playlist.canonicalID)"
    case let .video(video):
      return "video:\(video.canonicalID)"
    }
  }
}
