import SwiftUI

struct LiveConnectivityBanner: View {
  let instanceUnavailable: Bool
  let onOpenDownloads: () -> Void
  let onRetry: () -> Void

  var body: some View {
    HStack(spacing: 10) {
      Image(
        systemName: instanceUnavailable
          ? "server.rack"
          : "wifi.slash"
      )
        .foregroundStyle(.orange)

      VStack(alignment: .leading, spacing: 1) {
        Text(
          instanceUnavailable
            ? "Instance unavailable"
            : "No network connection"
        )
          .font(.subheadline.weight(.semibold))
          .accessibilityIdentifier("live.connectivity.banner")
        Text("Downloaded media stays available.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 4)

      Button("Downloads", action: onOpenDownloads)
        .liveProminentButton()
        .controlSize(.small)

      if instanceUnavailable {
        Button(action: onRetry) {
          Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityLabel("Retry instance connection")
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(.bar)
    .overlay(alignment: .bottom) {
      Divider()
    }
    .accessibilityElement(children: .contain)
  }
}
