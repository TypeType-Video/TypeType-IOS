import SwiftUI

extension LiveChannelView {
  var aboutContent: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("About")
        .font(.headline)
      if let channel = viewModel.channel, !channel.description.isEmpty {
        InteractiveText(text: channel.description, font: .subheadline, lineLimit: nil, onOpenURL: routeLink)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
      } else {
        Text("This channel has no description.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityIdentifier("live.channel.about")
  }
}
