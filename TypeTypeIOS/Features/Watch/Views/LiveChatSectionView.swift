import SwiftUI

struct LiveChatSectionView: View {
  @StateObject private var feed: LiveChatFeed
  @Environment(\.themePalette) private var palette

  init(videoURL: String, service: LiveChatService?) {
    _feed = StateObject(wrappedValue: LiveChatFeed(videoURL: videoURL, service: service))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Live chat")
          .font(.title3.weight(.bold))
        Spacer()
        Text(statusText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(feed.buffer.messages) { message in
              messageRow(message)
                .id(message.id)
            }
          }
          .padding(12)
        }
        .frame(height: 260)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onChange(of: feed.buffer.messages.last?.id) { _, last in
          guard let last else { return }
          withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(last, anchor: .bottom) }
        }
      }
    }
    .onAppear { feed.start() }
    .onDisappear { feed.stop() }
    .accessibilityIdentifier("live.chat.section")
  }

  private func messageRow(_ message: LiveChatMessage) -> some View {
    (Text(verbatim: message.author + "  ")
      .font(.subheadline.weight(.semibold))
      .foregroundColor(message.moderator ? .blue : .secondary)
      + Text(verbatim: message.text).font(.subheadline))
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
  }

  private var statusText: LocalizedStringKey {
    switch feed.buffer.status {
    case .connecting: "Connecting"
    case .connected: feed.buffer.messages.isEmpty ? "Waiting for messages" : "Live"
    case .ended: "The live has ended"
    case .unavailable: "No chat for this live"
    }
  }
}
