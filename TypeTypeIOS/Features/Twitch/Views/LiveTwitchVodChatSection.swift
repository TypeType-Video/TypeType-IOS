import SwiftUI

struct LiveTwitchVodChatSection: View {
  @ObservedObject var controller: LivePlayerController
  @StateObject private var model: LiveTwitchVodChatViewModel
  let onOpenURL: (URL) -> Void
  @State private var pendingURL: URL?

  init(controller: LivePlayerController, model: @autoclosure @escaping () -> LiveTwitchVodChatViewModel, onOpenURL: @escaping (URL) -> Void) {
    self.controller = controller
    _model = StateObject(wrappedValue: model())
    self.onOpenURL = onOpenURL
  }

  var body: some View {
    let comments = model.window.visibleComments(at: controller.position)
    VStack(alignment: .leading, spacing: 10) {
      Text("Chat replay").font(.headline)
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 6) {
            if model.unavailable {
              Text("The chat replay of this video is not available.").font(.footnote).foregroundStyle(.secondary)
            } else if comments.isEmpty {
              Text("No messages at this point of the video.").font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(comments) { comment in
              LiveTwitchChatMessageRow(
                author: comment.author,
                login: comment.login ?? comment.author,
                color: comment.color,
                badges: (comment.badges ?? []).compactMap { model.badges[$0] },
                parts: LiveTwitchChatParts.parts(text: comment.text, native: comment.emotes ?? [], emotes: model.emotes),
                onOpenURL: { pendingURL = $0 }
              )
            }
            Color.clear.frame(height: 1).id("bottom")
          }
          .padding(.vertical, 6)
        }
        .frame(height: 320)
        .onChange(of: comments.last?.id) { proxy.scrollTo("bottom", anchor: .bottom) }
      }
    }
    .task { await model.loadAssets() }
    .task(id: Int(controller.position)) { await model.follow(position: controller.position) }
    .liveTwitchExternalLinkConfirmation($pendingURL, onOpen: onOpenURL)
    .accessibilityIdentifier("live.twitch.chat-replay")
  }
}
