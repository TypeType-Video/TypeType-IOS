import SwiftUI

struct LiveAdminSessionRow: View {
  @Environment(\.themePalette) private var palette
  let session: LiveAdminSession

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Label(
          session.username ?? "Anonymous",
          systemImage: deviceSymbol
        )
        .font(.headline)
        Spacer()
        Text(activityDate.formatted(.relative(presentation: .named)))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      if let client = session.clientName {
        Text(
          [client, session.clientVersion]
            .compactMap { $0 }
            .joined(separator: " · ")
        )
        .font(.subheadline)
      }
      if let address = session.remoteAddress {
        Text(address)
          .font(.caption.monospaced())
          .foregroundStyle(.secondary)
      }
      if let playing = session.nowPlaying {
        Label(
          "\(playing.paused ? "Paused" : "Playing"): \(playing.title)",
          systemImage: playing.paused ? "pause.fill" : "play.fill"
        )
        .font(.caption)
        .foregroundStyle(palette.accent)
        .lineLimit(2)
      }
    }
    .padding(.vertical, 6)
    .accessibilityIdentifier("live.admin.session")
  }

  private var activityDate: Date {
    let value = session.lastActivityAt > 10_000_000_000
      ? TimeInterval(session.lastActivityAt) / 1_000
      : TimeInterval(session.lastActivityAt)
    return Date(timeIntervalSince1970: value)
  }

  private var deviceSymbol: String {
    switch session.deviceType?.lowercased() {
    case "mobile", "phone": return "iphone"
    case "tablet": return "ipad"
    case "tv": return "tv"
    default: return "desktopcomputer"
    }
  }
}
