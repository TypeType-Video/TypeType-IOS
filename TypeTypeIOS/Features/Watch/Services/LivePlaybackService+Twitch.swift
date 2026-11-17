import Foundation

extension LivePlaybackService {
  func twitchStream(for link: LiveTwitchLink) async throws -> LivePlaybackStream {
    do {
      return try await loadTwitchStream(for: link)
    } catch {
      throw LiveTwitchPlaybackError.translating(error)
    }
  }

  private func loadTwitchStream(for link: LiveTwitchLink) async throws -> LivePlaybackStream {
    let twitch = LiveTwitchService(apiClient: apiClient)
    let origin = serverURLProvider()
    switch link {
    case let .channel(login):
      return try LiveTwitchPlayback.stream(live: try await twitch.live(login: login), origin: origin)
    case let .video(id):
      async let answer = twitch.video(id: id)
      async let chapters = twitch.videoChapters(id: id)
      let playback = try await answer
      return try LiveTwitchPlayback.stream(video: playback, chapters: (try? await chapters) ?? [], origin: origin)
    case let .clip(slug):
      return try LiveTwitchPlayback.stream(clip: try await twitch.clip(slug: slug), origin: origin)
    }
  }

  // Twitch playlists are signed by the instance: AVPlayer reads them as they are, without the authenticated loader.
  func prepareTwitch(
    stream: LivePlaybackStream,
    media: LiveTwitchMedia,
    preferences: LivePlaybackPreferences
  ) -> LivePlaybackPreparation {
    LivePlaybackPreparation(
      stream: stream,
      assetURL: preferences.audioOnly ? media.audioURL ?? media.url : media.url,
      usesAuthenticatedLoader: false,
      video: nil,
      audio: nil,
      providerPlayback: nil,
      subtitles: [],
      resumeTime: 0,
      isSABR: false,
      audioOnly: preferences.audioOnly
    )
  }
}
