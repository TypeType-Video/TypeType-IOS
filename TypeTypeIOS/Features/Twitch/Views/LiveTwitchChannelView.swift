import SwiftUI

struct LiveTwitchChannelView: View {
  enum Section: Hashable {
    case videos, clips
  }

  let login: String
  @StateObject private var model: LiveTwitchChannelViewModel
  @StateObject private var videos: LiveTwitchPagedList<LiveTwitchVideo>
  @StateObject private var clips: LiveTwitchPagedList<LiveTwitchClip>
  @State private var section = Section.videos
  @Environment(\.liveTwitchPlay) private var play

  init(login: String, service: LiveTwitchServiceProtocol) {
    self.login = login
    _model = StateObject(wrappedValue: LiveTwitchChannelViewModel(login: login, service: service))
    _videos = StateObject(wrappedValue: LiveTwitchPagedList { try await service.channelVideos(login: login, after: $0) })
    _clips = StateObject(wrappedValue: LiveTwitchPagedList { try await service.channelClips(login: login, after: $0) })
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        switch model.state {
        case .loading:
          ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case let .failed(message):
          LiveTwitchMessage(text: Text(message), systemImage: "exclamationmark.triangle") {
            Task { await model.load() }
          }
        case .notFound:
          LiveTwitchMessage(text: Text("This channel could not be found."), systemImage: "person.crop.circle.badge.questionmark", retry: nil)
        case let .loaded(channel):
          LiveTwitchChannelHeader(channel: channel)
          if let live = channel.live {
            LiveTwitchChannelLive(stream: live)
          }
          sections
        }
      }
      .padding()
    }
    .background(LiveThemeBackground().ignoresSafeArea())
    .navigationTitle(model.title ?? login)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable { await reload() }
    .task { await model.load() }
    .accessibilityIdentifier("live.twitch.channel")
  }

  private var sections: some View {
    VStack(alignment: .leading, spacing: 16) {
      Picker("Channel sections", selection: $section) {
        Text("Past broadcasts").tag(Section.videos)
        Text("Clips").tag(Section.clips)
      }
      .pickerStyle(.segmented)
      switch section {
      case .videos:
        LiveTwitchPagedContent(list: videos, empty: "No past broadcasts.", identifier: "live.twitch.videos.more") { items in
          LazyVStack(spacing: 14) {
            ForEach(items) { video in
              LiveTwitchVideoCard(
                title: video.title,
                previewURL: video.previewURL,
                duration: video.lengthSeconds,
                detail: LiveTwitchFormat.videoDetail(views: video.views, created: video.createdAt),
                action: { play(LiveTwitchPlayback.item(video: video)) }
              )
            }
          }
        }
        .task { await videos.prepare() }
      case .clips:
        LiveTwitchPagedContent(list: clips, empty: "No clips.", identifier: "live.twitch.clips.more") { items in
          LazyVStack(spacing: 14) {
            ForEach(items) { clip in
              LiveTwitchVideoCard(
                title: clip.title,
                previewURL: clip.thumbnailURL,
                duration: Int(clip.durationSeconds.rounded()),
                detail: LiveTwitchFormat.videoDetail(views: clip.views, created: clip.createdAt),
                action: { play(LiveTwitchPlayback.item(clip: clip)) }
              )
            }
          }
        }
        .task { await clips.prepare() }
      }
    }
  }

  private func reload() async {
    await model.load()
    switch section {
    case .videos: await videos.reload()
    case .clips: await clips.reload()
    }
  }
}

struct LiveTwitchChannelHeader: View {
  let channel: LiveTwitchChannel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 14) {
        LiveTwitchAvatar(url: channel.user.avatarURL, size: 72)
        VStack(alignment: .leading, spacing: 4) {
          Text(verbatim: channel.user.name)
            .font(.title2.weight(.bold))
            .accessibilityAddTraits(.isHeader)
          Text("\(LiveTwitchFormat.count(channel.followers)) followers")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          if channel.live == nil {
            Text("Offline")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
          }
        }
      }
      LiveTwitchFollowRow(login: channel.user.login)
      if !channel.description.isEmpty {
        Text(verbatim: channel.description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }
}

struct LiveTwitchChannelLive: View {
  let stream: LiveTwitchStream
  @Environment(\.liveTwitchPlay) private var play

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Button { play(LiveTwitchPlayback.item(live: stream)) } label: {
        LiveTwitchStreamCard(stream: stream)
      }
      .buttonStyle(.plain)
      if let started = LiveTwitchFormat.date(stream.startedAt) {
        Text("Live for \(started, style: .relative)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      if !stream.tags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(stream.tags, id: \.self) { tag in
              NavigationLink(value: LiveTwitchRoute.tag(tag)) {
                Text(verbatim: tag)
                  .font(.caption.weight(.semibold))
                  .padding(.horizontal, 10)
                  .padding(.vertical, 5)
                  .background(.quaternary, in: Capsule())
              }
              .buttonStyle(.plain)
              .accessibilityLabel(Text("See the lives tagged \(tag)"))
            }
          }
        }
      }
    }
  }
}
