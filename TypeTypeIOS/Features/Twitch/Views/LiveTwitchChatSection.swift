import SwiftUI

struct LiveTwitchChatSection: View {
  @StateObject private var model: LiveTwitchChatViewModel
  let onOpenURL: (URL) -> Void
  @State private var pendingURL: URL?
  @State private var paused = false
  @State private var showsEmotes = false

  init(model: @autoclosure @escaping () -> LiveTwitchChatViewModel, onOpenURL: @escaping (URL) -> Void) {
    _model = StateObject(wrappedValue: model())
    self.onOpenURL = onOpenURL
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Chat").font(.headline)
        Spacer()
        if model.status != .live {
          Text(model.status == .reconnecting ? "Reconnecting to the chat…" : "Connecting to the chat…")
            .font(.caption).foregroundStyle(.secondary)
        }
      }
      if let pinned = model.visiblePinned {
        LiveTwitchPinnedCard(pinned: pinned) { model.hide(pinned.id) }
      }
      if let poll = model.visiblePoll {
        LiveTwitchPollCard(poll: poll, canVote: model.canWrite, voted: model.votedPollID == poll.id,
                           onVote: { choice in Task { await model.vote(choice) } }, onHide: { model.hide(poll.id) })
      }
      if let room = model.chat.room { LiveTwitchChatModes(room: room) }
      messages
      composer
      if let notice = model.notice {
        Text(verbatim: notice).font(.caption).foregroundStyle(.orange)
      }
    }
    .task { await model.run() }
    .sheet(isPresented: $showsEmotes) {
      LiveTwitchEmotePicker(model: model) { showsEmotes = false }
    }
    .liveTwitchExternalLinkConfirmation($pendingURL, onOpen: onOpenURL)
    .accessibilityIdentifier("live.twitch.chat")
  }

  private var messages: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 6) {
          if model.chat.messages.isEmpty {
            Text(model.status == .live ? "No messages yet. Say hi!" : "Connecting to the chat…")
              .font(.footnote).foregroundStyle(.secondary)
          }
          ForEach(model.chat.messages) { event in row(event) }
          Color.clear.frame(height: 1).id("bottom")
        }
        .padding(.vertical, 6)
      }
      .frame(height: 320)
      .simultaneousGesture(DragGesture(minimumDistance: 8).onChanged { _ in paused = true })
      .onChange(of: model.chat.messages.last?.id) {
        if !paused { proxy.scrollTo("bottom", anchor: .bottom) }
      }
      .overlay(alignment: .bottom) {
        if paused {
          Button("New messages") {
            paused = false
            withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
          .padding(.bottom, 6)
        }
      }
    }
  }

  @ViewBuilder
  private func row(_ event: LiveTwitchChatEvent) -> some View {
    if event.kind == .message, let text = event.text {
      LiveTwitchChatMessageRow(
        author: event.author,
        color: event.color,
        badges: event.badges.compactMap { model.badges[$0] },
        parts: LiveTwitchChatParts.parts(text: text, native: event.emotes, emotes: model.emotes, selfLogin: model.account?.login ?? ""),
        deleted: event.deleted,
        isAction: event.action,
        onOpenURL: { pendingURL = $0 }
      )
    } else if let text = event.system ?? event.text {
      Text(verbatim: text).font(.caption).foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var composer: some View {
    if model.canWrite {
      HStack(spacing: 8) {
        Button { showsEmotes = true } label: { Image(systemName: "face.smiling") }
          .accessibilityLabel(Text("Emotes"))
        TextField("Send a message", text: $model.draft)
          .textFieldStyle(.roundedBorder)
          .submitLabel(.send)
          .onSubmit { Task { await model.send() } }
        Button("Send") { Task { await model.send() } }
          .disabled(model.isSending || model.draft.trimmingCharacters(in: .whitespaces).isEmpty)
      }
    } else {
      Text("Link a Twitch account to chat.").font(.footnote).foregroundStyle(.secondary)
    }
  }
}

struct LiveTwitchEmotePicker: View {
  @ObservedObject var model: LiveTwitchChatViewModel
  let onDone: () -> Void
  @State private var query = ""

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          section("Twitch", model.userEmotes.filter(matches).map { LiveTwitchChatParts.twitchEmote(id: $0.id, name: $0.name) })
          section("Channel", model.emotes.values.filter { matches($0.name) }.sorted { $0.name < $1.name }
            .map { LiveTwitchEmoteImage(name: $0.name, url: URL(string: $0.url2x ?? $0.url)) })
        }
        .padding()
      }
      .searchable(text: $query, prompt: Text("Search an emote"))
      .navigationTitle("Emotes")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done", action: onDone) } }
      .task { await model.loadUserEmotes() }
    }
    .presentationDetents([.medium, .large])
  }

  private func matches(_ emote: LiveTwitchUserEmote) -> Bool { matches(emote.name) }

  private func matches(_ name: String) -> Bool {
    query.isEmpty || name.localizedCaseInsensitiveContains(query)
  }

  @ViewBuilder
  private func section(_ title: LocalizedStringKey, _ emotes: [LiveTwitchEmoteImage]) -> some View {
    if !emotes.isEmpty {
      Text(title).font(.headline)
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
        ForEach(emotes, id: \.name) { emote in
          Button { model.insert(emote.name) } label: {
            LiveRemoteImage(url: emote.url, contentMode: .fit).frame(width: 36, height: 36)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(Text(verbatim: emote.name))
        }
      }
    }
  }
}
