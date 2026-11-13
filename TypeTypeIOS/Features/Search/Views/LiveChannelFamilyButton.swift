import SwiftUI

struct LiveChannelFamilyButton: View {
  let channelURL: String
  let name: String
  let avatarURL: String
  let service: LiveAllowedChannelsServiceProtocol
  @State private var allowed = false
  @State private var busy = false
  @State private var failed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Button {
        Task { await allow() }
      } label: {
        Label(
          allowed ? "In the family list" : "Add to the family list",
          systemImage: allowed ? "checkmark" : "figure.2.and.child.holdinghands"
        )
      }
      .buttonStyle(.bordered)
      .disabled(allowed || busy)
      .accessibilityIdentifier("live.channel.family")
      if failed {
        Text("The channel could not be added. Try again.")
          .font(.caption)
          .foregroundStyle(.red)
      }
    }
    .task(id: channelURL) {
      allowed = (try? await service.allowedChannelURLs())?.contains(channelURL) ?? false
    }
  }

  private func allow() async {
    guard !busy, !allowed else { return }
    busy = true
    defer { busy = false }
    do {
      try await service.allowForEveryone(channelURL: channelURL, name: name, avatarURL: avatarURL.isEmpty ? nil : avatarURL)
      allowed = true
      failed = false
    } catch {
      failed = true
    }
  }
}
