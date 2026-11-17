import SwiftUI

struct LiveTwitchWatchExtras: View {
  @ObservedObject var controller: LivePlayerController
  let onRewind: (LiveTwitchArchive, TimeInterval) -> Void
  @State private var showsChapters = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if controller.stream?.isLive == true, let live = controller.stream?.twitchMedia?.live {
        LiveTwitchLiveDetails(stream: live, onRewind: onRewind)
      }
      if controller.offersTwitchAudioOnly {
        Toggle(isOn: Binding(get: { controller.audioOnly }, set: { controller.setAudioOnly($0) })) {
          Label("Audio only", systemImage: "headphones")
            .font(.subheadline.weight(.semibold))
        }
        .accessibilityHint(Text("Plays the sound without the picture."))
        .accessibilityIdentifier("live.twitch.audio-only")
      }
      if controller.stream?.isLive != true, !(controller.stream?.chapters.isEmpty ?? true) {
        Button { showsChapters = true } label: {
          Label("Chapters", systemImage: "list.bullet.rectangle")
            .font(.subheadline.weight(.semibold))
        }
        .accessibilityIdentifier("live.twitch.chapters")
      }
    }
    .sheet(isPresented: $showsChapters) {
      LivePlayerChaptersView(controller: controller) { showsChapters = false }
    }
  }
}
