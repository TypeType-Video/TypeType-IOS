import SwiftUI

struct LiveTwitchPinnedCard: View {
  let pinned: LiveTwitchPinnedMessage
  let onHide: () -> Void
  @State private var expanded = false

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: "pin.fill").font(.caption).foregroundStyle(.purple).accessibilityHidden(true)
      Button { expanded.toggle() } label: {
        VStack(alignment: .leading, spacing: 2) {
          if let by = pinned.pinnedBy {
            Text("Pinned by \(by)").font(.caption2).foregroundStyle(.secondary)
          }
          Text(verbatim: "\(pinned.author): \(pinned.text)")
            .font(.footnote)
            .lineLimit(expanded ? nil : 2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel(Text("Pinned message"))
      .accessibilityValue(Text(verbatim: "\(pinned.author): \(pinned.text)"))
      .accessibilityHint(expanded ? Text("Shows less of the message.") : Text("Shows the whole message."))
      Button(action: onHide) { Image(systemName: "xmark").font(.caption) }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel(Text("Hide"))
    }
    .padding(10)
    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
  }
}

struct LiveTwitchPollCard: View {
  let poll: LiveTwitchPoll
  let canVote: Bool
  let voted: Bool
  let onVote: (LiveTwitchPollChoice) -> Void
  let onHide: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Label(poll.isActive ? "Poll" : "Poll ended", systemImage: "chart.bar.fill")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.purple)
        Spacer()
        Text("\(poll.votes) votes").font(.caption2).foregroundStyle(.secondary)
        Button(action: onHide) { Image(systemName: "xmark").font(.caption) }
          .buttonStyle(.plain)
          .foregroundStyle(.secondary)
          .accessibilityLabel(Text("Hide"))
      }
      Text(verbatim: poll.title).font(.subheadline.weight(.semibold))
      ForEach(poll.choices) { choice in
        let percent = LiveTwitchChatText.percent(choice, in: poll)
        Button { onVote(choice) } label: {
          ZStack(alignment: .leading) {
            GeometryReader { proxy in
              RoundedRectangle(cornerRadius: 6).fill(Color.purple.opacity(0.25))
                .frame(width: proxy.size.width * CGFloat(percent) / 100)
            }
            HStack {
              Text(verbatim: choice.title).font(.footnote)
              Spacer()
              Text(verbatim: "\(percent)%").font(.footnote.monospacedDigit())
            }
            .padding(.horizontal, 8)
          }
          .frame(height: 30)
          .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .disabled(!canVote || voted || !poll.isActive)
        .accessibilityLabel(Text("Vote for \(choice.title) (\(percent)%)"))
      }
    }
    .padding(10)
    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
  }
}

struct LiveTwitchChatModes: View {
  let room: LiveTwitchRoomState

  var body: some View {
    let modes = LiveTwitchChatText.modes(room)
    if !modes.isEmpty {
      Text(verbatim: modes.joined(separator: " · "))
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
    }
  }
}
