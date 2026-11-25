import SwiftUI

struct LiveTwitchWatchInfos: View {
  @ObservedObject var controller: LivePlayerController
  let video: LiveVideoItem
  let dependencies: AppDependencies

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      if controller.stream?.isLive == true, let tags = controller.stream?.twitchMedia?.live?.tags, !tags.isEmpty {
        Text(verbatim: tags.joined(separator: " · "))
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      if controller.offersTwitchAudioOnly {
        Toggle(isOn: Binding(get: { controller.audioOnly }, set: { controller.setAudioOnly($0) })) {
          Label("Audio only", systemImage: "headphones")
            .font(.subheadline.weight(.semibold))
        }
        .accessibilityHint(Text("Plays the sound without the picture."))
        .accessibilityIdentifier("live.twitch.audio-only")
      }
      LiveVideoLibraryActionsView(video: video, dependencies: dependencies)
      if controller.stream?.isLive != true, let chapters = controller.stream?.chapters, !chapters.isEmpty {
        chaptersList(chapters)
      }
      LivePlaybackQueueView(coordinator: dependencies.playbackCoordinator)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func chaptersList(_ chapters: [LivePlaybackChapter]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Chapters").font(.headline)
      ForEach(chapters) { chapter in
        let start = TimeInterval(chapter.startTimeSeconds)
        Button { controller.seek(to: start) } label: {
          HStack(spacing: 12) {
            Text(verbatim: LiveTwitchFormat.clock(start))
              .font(.subheadline.monospacedDigit())
              .foregroundStyle(.secondary)
              .frame(minWidth: 64, alignment: .leading)
            Text(verbatim: chapter.title).font(.subheadline).lineLimit(2)
            Spacer(minLength: 0)
            if chapter.id == current(in: chapters)?.id {
              Image(systemName: "play.fill").font(.caption).foregroundStyle(.tint)
            }
          }
          .padding(.vertical, 6)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "\(chapter.title), \(LiveTwitchFormat.clock(start))"))
      }
    }
    .accessibilityIdentifier("live.twitch.chapters")
  }

  private func current(in chapters: [LivePlaybackChapter]) -> LivePlaybackChapter? {
    chapters.last { TimeInterval($0.startTimeSeconds) <= controller.position }
  }
}
