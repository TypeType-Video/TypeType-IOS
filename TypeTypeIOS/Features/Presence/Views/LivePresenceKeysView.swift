import SwiftUI

struct LivePresenceKeysView: View {
  @StateObject private var model: LivePresenceKeysViewModel
  @Environment(\.liveToasts) private var toasts

  init(service: LivePresenceServiceProtocol) {
    _model = StateObject(wrappedValue: LivePresenceKeysViewModel(service: service))
  }

  var body: some View {
    List {
      if let token = model.createdToken {
        LiveSection {
          Text(verbatim: token).font(.footnote.monospaced()).textSelection(.enabled)
          Button("Copy key") {
            UIPasteboard.general.string = token
            toasts?.show(String(localized: "Key copied"))
          }
        } header: {
          Text("Copy this key now. It will not be shown again.").liveSectionHeader()
        }
      }
      LiveSection {
        TextField("Key name", text: $model.name, prompt: Text(verbatim: "Discord RPC"))
          .onChange(of: model.name) { _, value in
            if value.count > LivePresenceKeysViewModel.nameLimit { model.name = String(value.prefix(LivePresenceKeysViewModel.nameLimit)) }
          }
          .submitLabel(.done)
          .onSubmit { Task { await model.create() } }
        Button("Create key") { Task { await model.create() } }
          .disabled(!model.canCreate)
      } header: {
        Text("Presence access").liveSectionHeader()
      } footer: {
        Text("Create a revocable key that can only see whether something is playing now.").liveSettingsFooter()
      }
      LiveSection {
        if model.loaded, model.keys.isEmpty { Text("No API keys yet.").foregroundStyle(.secondary) }
        if !model.loaded { ProgressView().frame(maxWidth: .infinity) }
        ForEach(model.keys) { key in
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(verbatim: key.name)
              Text(verbatim: detail(key)).font(.footnote.monospaced()).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Revoke", role: .destructive) { Task { await model.revoke(key) } }
              .buttonStyle(.borderless)
          }
          .accessibilityElement(children: .combine)
          .accessibilityAction(named: Text("Revoke")) { Task { await model.revoke(key) } }
        }
      } footer: {
        if let error = model.error { Text(verbatim: error).liveSettingsFooter() }
      }
    }
    .liveGroupedList()
    .navigationTitle("API")
    .navigationBarTitleDisplayMode(.inline)
    .task { await model.load() }
  }

  private func detail(_ key: LivePresenceKey) -> String {
    let created = Date(timeIntervalSince1970: TimeInterval(key.createdAt) / 1000).formatted(date: .abbreviated, time: .omitted)
    return "\(key.tokenPrefix)… · \(created)"
  }
}
