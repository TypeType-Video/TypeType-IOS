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

struct LiveTwitchFlowLayout: Layout {
  var spacing: CGFloat
  var lineSpacing: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
    return CGSize(width: rows.map(\.width).max() ?? 0, height: rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(rows.count - 1, 0)))
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    var y = bounds.minY
    for row in arrange(width: bounds.width, subviews: subviews) {
      var x = bounds.minX
      for index in row.indices {
        let size = subviews[index].sizeThatFits(.unspecified)
        subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: ProposedViewSize(size))
        x += size.width + spacing
      }
      y += row.height + lineSpacing
    }
  }

  private struct Row {
    var indices: [Int] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
  }

  private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
    var rows = [Row()]
    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
      if needed > width, !rows[rows.count - 1].indices.isEmpty {
        rows.append(Row())
      }
      var row = rows[rows.count - 1]
      row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
      row.height = max(row.height, size.height)
      row.indices.append(index)
      rows[rows.count - 1] = row
    }
    return rows
  }
}
