import SwiftUI

struct DemoAdminAllowListView: View {
  @EnvironmentObject private var session: DemoSessionStore
  @State private var channelDraft = ""
  @State private var playlistDraft = ""

  var body: some View {
    Form {
      Section {
        Picker("Access mode", selection: $session.isInstanceAllowListRestricted) {
          Text("Unrestricted").tag(false)
          Text("Allow list").tag(true)
        }
        .pickerStyle(.segmented)
      } header: { Text("Entire instance").liveSectionHeader() }

      addSection(
        title: "Global channels",
        prompt: "Channel name or handle",
        draft: $channelDraft,
        values: session.globalAllowedChannels,
        add: addChannel,
        remove: removeChannel
      )

      addSection(
        title: "Global playlists",
        prompt: "Playlist name or URL",
        draft: $playlistDraft,
        values: session.globalAllowedPlaylists,
        add: addPlaylist,
        remove: removePlaylist
      )

      Section {
        ForEach(session.adminUsers) { user in
          Toggle(
            user.name,
            isOn: restrictedBinding(for: user.id)
          ).liveRowFill()
        }
      } header: { Text("User access").liveSectionHeader() } footer: {
        Text("Enabled means this user has a user-specific allow list.").liveSectionSlotChrome()
      }

      Section {
        ForEach(session.adminUsers) { user in
          NavigationLink(user.name) {
            DemoAdminUserAllowListView(userID: user.id)
          }
        }
      } header: { Text("Specific user lists").liveSectionHeader() }
    }
  }

  private func addSection(
    title: String,
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

  private func addChannel() {
    add(channelDraft, to: &session.globalAllowedChannels)
    channelDraft = ""
  }

  private func addPlaylist() {
    add(playlistDraft, to: &session.globalAllowedPlaylists)
    playlistDraft = ""
  }

  private func add(_ draft: String, to values: inout [String]) {
    let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, !values.contains(value) else { return }
    values.append(value)
  }

  private func removeChannel(_ value: String) {
    session.globalAllowedChannels.removeAll { $0 == value }
  }

  private func removePlaylist(_ value: String) {
    session.globalAllowedPlaylists.removeAll { $0 == value }
  }

  private func restrictedBinding(for userID: String) -> Binding<Bool> {
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
}
