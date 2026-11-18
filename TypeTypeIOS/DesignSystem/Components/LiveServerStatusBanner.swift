import SwiftUI

struct LiveServerStatusBanner: View {
  @ObservedObject var monitor: LiveServerStatusMonitor

  var body: some View {
    if let message = monitor.message {
      HStack(spacing: 8) {
        if monitor.isWaiting {
          ProgressView().controlSize(.small).tint(.white)
        } else if monitor.status.notice != nil {
          Image(systemName: "wrench.and.screwdriver.fill")
        } else {
          Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        }
        Text(verbatim: message).font(.footnote.weight(.medium)).multilineTextAlignment(.leading)
      }
      .foregroundStyle(.white)
      .padding(.horizontal, 14)
      .padding(.vertical, 9)
      .background(Color.black.opacity(0.85), in: Capsule())
      .overlay(Capsule().strokeBorder(.white.opacity(0.15)))
      .padding(.horizontal, 16)
      .transition(.move(edge: .top).combined(with: .opacity))
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.updatesFrequently)
      .accessibilityIdentifier("live.server.status")
    }
  }
}
