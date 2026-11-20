import SwiftUI

struct LiveTwitchChatMessageRow: View {
  let author: String
  let login: String
  let color: String?
  let badges: [LiveTwitchChatBadge]
  let parts: [LiveTwitchChatPart]
  var deleted = false
  var isAction = false
  let onOpenURL: (URL) -> Void
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    LiveTwitchFlowLayout(spacing: 3, lineSpacing: 4) {
      ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
        LiveRemoteImage(url: URL(string: badge.url2x ?? badge.url), contentMode: .fit)
          .frame(width: 18, height: 18)
          .accessibilityLabel(Text(verbatim: badge.title))
      }
      Text(verbatim: author + (isAction ? "" : ":"))
        .font(.subheadline.weight(.bold))
        .foregroundStyle(LiveTwitchChatText.nameColor(color, login: login, dark: colorScheme == .dark))
      if deleted {
        Text("Message deleted by a moderator")
          .font(.subheadline.italic())
          .foregroundStyle(.secondary)
      } else {
        ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
          view(for: token)
        }
      }
    }
    .accessibilityElement(children: .combine)
  }

  private enum Token {
    case word(String)
    case emote(LiveTwitchEmoteImage, [LiveTwitchEmoteImage])
    case link(String, URL)
    case mention(String, Bool)
  }

  private var tokens: [Token] {
    parts.flatMap { part -> [Token] in
      switch part {
      case let .text(text): text.split(whereSeparator: \.isWhitespace).map { .word(String($0)) }
      case let .emote(image, overlays): [.emote(image, overlays)]
      case let .link(text, url): [.link(text, url)]
      case let .mention(text, isSelf): [.mention(text, isSelf)]
      }
    }
  }

  @ViewBuilder
  private func view(for token: Token) -> some View {
    switch token {
    case let .word(word):
      Text(verbatim: word).font(.subheadline).italic(isAction)
    case let .emote(image, overlays):
      ZStack {
        LiveRemoteImage(url: image.url, contentMode: .fit)
        ForEach(Array(overlays.enumerated()), id: \.offset) { _, overlay in
          LiveRemoteImage(url: overlay.url, contentMode: .fit)
        }
      }
      .frame(width: 26, height: 26)
      .accessibilityLabel(Text(verbatim: ([image] + overlays).map(\.name).joined(separator: " ")))
    case let .link(text, url):
      Button { onOpenURL(url) } label: {
        Text(verbatim: text).font(.subheadline).underline()
      }
      .buttonStyle(.plain)
      .foregroundStyle(.tint)
      .accessibilityLabel(Text("External link: \(url.absoluteString)"))
    case let .mention(text, isSelf):
      Text(verbatim: text)
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, isSelf ? 3 : 0)
        .background(isSelf ? Color.accentColor.opacity(0.25) : .clear, in: RoundedRectangle(cornerRadius: 4))
    }
  }
}
