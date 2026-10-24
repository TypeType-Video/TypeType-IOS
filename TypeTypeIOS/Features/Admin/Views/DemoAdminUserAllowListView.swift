import SwiftUI

struct DemoAdminUserAllowListView: View {
  @EnvironmentObject private var session: DemoSessionStore
  let userID: String
  @State private var channelDraft = ""
  @State private var playlistDraft = ""

  var body: some View {
    Form {
      Section {
        Toggle("User-specific allow list", isOn: restricted)
        Text(accessSummary)
          .font(.caption)
          .foregroundStyle(.secondary)
      } header: { Text("Access mode").liveSectionHeader() }

      inheritedSection(
        "Inherited global channels",
        values: session.globalAllowedChannels
      )
      inheritedSection(
        "Inherited global playlists",
        values: session.globalAllowedPlaylists
      )

      editableSection(
        "User channels",
        prompt: "Channel name or handle",
        draft: $channelDraft,
        values: userChannels,
        add: addChannel,
        remove: removeChannel
      )
      editableSection(
        "User playlists",
        prompt: "Playlist name or URL",
        draft: $playlistDraft,
        values: userPlaylists,
        add: addPlaylist,
        remove: removePlaylist
      )
    }
    .navigationTitle(userName)
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("demo.admin.user-allow-list")
  }

  private func inheritedSection(
    _ title: String,
    values: [String]
  ) -> some View {
    Section(title) {
      if values.isEmpty {
        Text("Nothing inherited.")
          .foregroundStyle(.secondary)
      } else {
        ForEach(values, id: \.self) { Text($0) }
      }
    }
  }

  private func editableSection(
    _ title: String,
    prompt: String,
    draft: Binding<String>,
    values: [String],
    add: @escaping () -> Void,
    remove: @escaping (String) -> Void
  ) -> some View {
    Section(title) {
      HStack {
        TextField(prompt, text: draft)
        Button("Add", action: add)
          .disabled(draft.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
      }
      if values.isEmpty {
        Text("No user-specific entries.")
          .foregroundStyle(.secondary)
      }
      ForEach(values, id: \.self) { value in
        HStack {
          Text(value)
          Spacer()
          Button("Remove", role: .destructive) {
            remove(value)
          }
        }
      }
    }
  }

  private var restricted: Binding<Bool> {
    Binding(
      get: { session.restrictedAdminUserIDs.contains(userID) },
      set: { enabled in
        if enabled {
          session.restrictedAdminUserIDs.insert(userID)
        } else {
          session.restrictedAdminUserIDs.remove(userID)
        }
      }
    )
  }

  private var accessSummary: String {
    if restricted.wrappedValue {
      return "This account uses its own entries plus the inherited global lists."
    }
    return session.isInstanceAllowListRestricted
      ? "This account has an unrestricted administrator override."
      : "This account is unrestricted."
  }

  private var userName: String {
    session.adminUsers.first { $0.id == userID }?.name ?? "User allow list"
  }

  private var userChannels: [String] {
    Array(session.userAllowedChannels[userID, default: []]).sorted()
  }

  private var userPlaylists: [String] {
    Array(session.userAllowedPlaylists[userID, default: []]).sorted()
  }

  private func addChannel() {
    add(channelDraft, to: &session.userAllowedChannels[userID, default: []])
    channelDraft = ""
  }

  private func addPlaylist() {
    add(playlistDraft, to: &session.userAllowedPlaylists[userID, default: []])
    playlistDraft = ""
  }

  private func add(_ draft: String, to values: inout Set<String>) {
    let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else { return }
    values.insert(value)
  }

  private func removeChannel(_ value: String) {
    session.userAllowedChannels[userID, default: []].remove(value)
  }

  private func removePlaylist(_ value: String) {
    session.userAllowedPlaylists[userID, default: []].remove(value)
  }
}
