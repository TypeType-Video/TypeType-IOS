import SwiftUI

struct LiveTwitchLinkSection: View {
  @StateObject private var model: LiveTwitchLinkViewModel
  @Environment(\.openURL) private var openURL

  init(service: LiveTwitchAccountServiceProtocol) {
    _model = StateObject(wrappedValue: LiveTwitchLinkViewModel(service: service))
  }

  var body: some View {
    LiveSection {
      if model.isLinked {
        Label {
          Text(verbatim: model.status?.name ?? "")
        } icon: {
          Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
        }
        Button("Unlink", role: .destructive) { Task { await model.unlink() } }
          .disabled(model.isBusy)
      } else if let device = model.device {
        VStack(alignment: .leading, spacing: 8) {
          Text("Enter this code on twitch.tv/activate:")
          Text(verbatim: device.userCode)
            .font(.title.monospaced().weight(.bold))
            .textSelection(.enabled)
            .accessibilityIdentifier("live.linked.twitch-code")
          ProgressView().controlSize(.small)
        }
        if let url = URL(string: device.verificationURI) {
          Button("Open twitch.tv/activate") { openURL(url) }
        }
        Button("Cancel", role: .cancel) { model.cancel() }
      } else if model.status == nil, model.error == nil {
        ProgressView()
      } else {
        Button("Link a Twitch account") { model.start() }
          .accessibilityIdentifier("live.linked.twitch-connect")
      }
    } header: {
      Text("Twitch").liveSectionHeader()
    } footer: {
      VStack(alignment: .leading, spacing: 6) {
        if let error = model.error { Text(verbatim: error).foregroundStyle(.red) }
        Text("To chat, vote in polls and follow channels with your Twitch account.")
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .task { await model.refresh() }
    .onDisappear { model.cancel() }
  }
}

struct LiveTwitchLinkPage: View {
  let service: LiveTwitchAccountServiceProtocol

  var body: some View {
    List { LiveTwitchLinkSection(service: service) }
      .liveGroupedList()
      .navigationTitle("Twitch")
      .navigationBarTitleDisplayMode(.inline)
  }
}
