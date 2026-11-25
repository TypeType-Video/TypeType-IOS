import SwiftUI

struct LiveTwitchWatchPage: View {
  enum Pane: Hashable {
    case chat, infos
  }

  static let chatColumnWidth: CGFloat = 360

  @ObservedObject var controller: LivePlayerController
  let video: LiveVideoItem
  let dependencies: AppDependencies
  let signedIn: Bool
  let wide: Bool
  let onChannel: () -> Void
  let onOpenURL: (URL) -> Void
  @State private var pane = Pane.chat
  @State private var linksAccount = false

  var body: some View {
    Group {
      if wide {
        HStack(spacing: 0) {
          VStack(spacing: 0) {
            playerSpace
            ScrollView {
              VStack(alignment: .leading, spacing: 0) {
                LiveTwitchWatchHeader(controller: controller, video: video, onChannel: onChannel, onLink: link)
                LiveTwitchWatchInfos(controller: controller, video: video, dependencies: dependencies)
              }
            }
          }
          if hasChat {
            Divider()
            chat.frame(width: Self.chatColumnWidth)
          }
        }
      } else {
        VStack(spacing: 0) {
          playerSpace
          LiveTwitchWatchHeader(controller: controller, video: video, onChannel: onChannel, onLink: link)
          if hasChat {
            Picker("Section", selection: $pane) {
              (isLive ? Text("Chat") : Text("Chat replay")).tag(Pane.chat)
              Text("Infos").tag(Pane.infos)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .accessibilityIdentifier("live.twitch.pane")
          }
          if hasChat, pane == .chat {
            chat
          } else {
            ScrollView {
              LiveTwitchWatchInfos(controller: controller, video: video, dependencies: dependencies)
            }
          }
        }
      }
    }
    .environment(\.liveTwitchAccount, signedIn ? dependencies.twitchAccountService : nil)
    .sheet(isPresented: $linksAccount) {
      if let service = dependencies.twitchAccountService {
        NavigationStack {
          LiveTwitchLinkPage(service: service)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { linksAccount = false } } }
        }
      }
    }
  }

  private var playerSpace: some View {
    Color.clear.aspectRatio(16 / 9, contentMode: .fit)
  }

  private var link: (() -> Void)? {
    signedIn ? { linksAccount = true } : nil
  }

  private var isLive: Bool { controller.stream?.isLive == true }

  private var hasChat: Bool {
    guard dependencies.twitchAccountService != nil else { return false }
    switch video.twitchLink {
    case .channel: return isLive && dependencies.twitchChatService != nil
    case .video: return true
    default: return false
    }
  }

  @ViewBuilder
  private var chat: some View {
    if let service = dependencies.twitchAccountService {
      switch video.twitchLink {
      case let .channel(login):
        if let chatService = dependencies.twitchChatService {
          LiveTwitchChatSection(
            model: LiveTwitchChatViewModel(login: login, chatService: chatService, service: service, signedIn: signedIn),
            onOpenURL: onOpenURL,
            onLink: { linksAccount = true }
          )
          .id(login)
        }
      case let .video(id):
        LiveTwitchVodChatSection(
          controller: controller,
          model: LiveTwitchVodChatViewModel(videoID: id, login: video.twitchOwnerLogin, service: service),
          onOpenURL: onOpenURL
        )
        .id(id)
      default:
        EmptyView()
      }
    }
  }
}

extension LiveVideoItem {
  var twitchOwnerLogin: String? {
    guard case let .channel(login) = URL(string: uploaderURL).flatMap(LiveTwitchLink.target(for:)) else { return nil }
    return login
  }
}
