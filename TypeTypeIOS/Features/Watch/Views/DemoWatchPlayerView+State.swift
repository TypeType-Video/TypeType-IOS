import SwiftUI

extension DemoWatchPlayerView {
  @ViewBuilder
  var playerPresentationOverlay: some View {
    if session.preferences.bulletComments {
      DemoBulletCommentOverlay(preferences: session.preferences)
    }

    switch session.preferences.playerDemoState {
    case "Live":
      Text("LIVE")
        .font(.caption2.weight(.black))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.red)
        .clipShape(Capsule())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(12)
        .allowsHitTesting(false)
    case "Members only":
      recoveryOverlay(
        title: "Members-only video",
        message: "This mock account does not have access.",
        symbol: "person.badge.key"
      )
    case "Premiere scheduled":
      recoveryOverlay(
        title: "Premiere scheduled",
        message: "This premiere starts in 2 hours.",
        symbol: "calendar.badge.clock"
      )
    case "Paid video":
      recoveryOverlay(
        title: "Paid video",
        message: "Purchase this video on YouTube before playing it.",
        symbol: "creditcard"
      )
    case "Outside family list":
      recoveryOverlay(
        title: "Outside the family list",
        message: "An administrator can add this channel.",
        symbol: "person.crop.circle.badge.xmark"
      )
    case "YouTube reconnect":
      recoveryOverlay(
        title: "Reconnect YouTube",
        message: "This browser-only video needs a connected session.",
        symbol: "person.crop.circle.badge.exclamationmark"
      )
    case "Region blocked":
      recoveryOverlay(
        title: "Unavailable in France",
        message: "The source reports a regional restriction for FR.",
        symbol: "globe.europe.africa"
      )
    case "Unavailable":
      recoveryOverlay(
        title: "Video unavailable",
        message: "Switch back to the normal demo state to retry.",
        symbol: "exclamationmark.triangle"
      )
    default:
      EmptyView()
    }
  }

  private func recoveryOverlay(
    title: String,
    message: String,
    symbol: String
  ) -> some View {
    VStack(spacing: 9) {
      Image(systemName: symbol).font(.title2)
      Text(title).font(.headline)
      Text(message).font(.caption).foregroundStyle(.secondary)
      Button("Return to playable demo") {
        session.setPreference(\.playerDemoState, to: "Normal")
      }
      .buttonStyle(.borderedProminent)
    }
    .foregroundStyle(.white)
    .multilineTextAlignment(.center)
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black.opacity(0.92))
  }
}
