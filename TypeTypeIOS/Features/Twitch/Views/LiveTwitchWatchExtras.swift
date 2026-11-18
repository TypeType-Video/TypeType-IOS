import SwiftUI

struct LiveTwitchWatchExtras: View {
  @ObservedObject var controller: LivePlayerController
  let dependencies: AppDependencies
  let signedIn: Bool
  let onRewind: (LiveTwitchArchive, TimeInterval) -> Void
  let onOpenURL: (URL) -> Void
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
      chat
    }
    .sheet(isPresented: $showsChapters) {
      LivePlayerChaptersView(controller: controller) { showsChapters = false }
    }
  }

  @ViewBuilder
  private var chat: some View {
    if let service = dependencies.twitchAccountService, let link = controller.video.twitchLink {
      switch link {
      case let .channel(login):
        if controller.stream?.isLive == true, let chatService = dependencies.twitchChatService {
          LiveTwitchChatSection(
            model: LiveTwitchChatViewModel(login: login, chatService: chatService, service: service, signedIn: signedIn),
            onOpenURL: onOpenURL
          )
          .id(login)
        }
      case let .video(id):
        let owner = URL(string: controller.video.uploaderURL).flatMap(LiveTwitchLink.target(for:))
        LiveTwitchVodChatSection(
          controller: controller,
          model: LiveTwitchVodChatViewModel(videoID: id, login: owner.flatMap { if case let .channel(login) = $0 { login } else { nil } }, service: service),
          onOpenURL: onOpenURL
        )
        .id(id)
      case .clip:
        EmptyView()
      }
    }
  }
}
