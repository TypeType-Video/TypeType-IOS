import SwiftUI

struct DemoSaveToPlaylistSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var session: DemoSessionStore
  let video: DemoVideo
  let onDone: (String) -> Void

  @State private var selectedIDs: Set<String> = ["watch-later"]
  @State private var newPlaylistName = ""

  var body: some View {
    NavigationStack {
      List {
        Section {
          TextField("Playlist name", text: $newPlaylistName)
          Button("Create and save", systemImage: "plus") {
            createPlaylist()
          }
          .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } header: { Text("New playlist").liveSectionHeader() }

        Section {
          ForEach(session.playlists) { playlist in
            Button {
              toggle(playlist)
            } label: {
              HStack(spacing: 12) {
                Image(playlist.artwork.rawValue)
                  .resizable()
                  .interpolation(.none)
                  .scaledToFit()
                  .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                  Text(playlist.title)
                  Text(playlist.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Image(
                  systemName: selectedIDs.contains(playlist.id)
                    ? "checkmark.circle.fill"
                    : "circle"
                )
                .foregroundStyle(
                  selectedIDs.contains(playlist.id)
                    ? Color(red: 1, green: 0.31, blue: 0.34)
                    : .secondary
                )
              }
            }
            .buttonStyle(.plain)
          }
        } header: { Text("Save to playlist").liveSectionHeader() }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Save")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            saveMembership()
            onDone(
              selectedIDs.isEmpty
                ? "Removed from every playlist"
                : "Saved to \(selectedIDs.count) playlist\(selectedIDs.count == 1 ? "" : "s")"
            )
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .preferredColorScheme(session.preferences.colorScheme)
    .accessibilityIdentifier("demo.watch.save")
    .onAppear(perform: loadMembership)
  }

  private func toggle(_ playlist: DemoPlaylist) {
    if selectedIDs.contains(playlist.id) {
      selectedIDs.remove(playlist.id)
    } else {
      selectedIDs.insert(playlist.id)
    }
  }

  private func createPlaylist() {
    let name = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return }
    let playlistID = session.createPlaylist(
      named: name,
      containing: video.id,
      artwork: video.artwork
    )
    selectedIDs.insert(playlistID)
    newPlaylistName = ""
  }

  private func loadMembership() {
    selectedIDs = Set(
      session.playlists.compactMap { playlist in
        isIncluded(in: playlist.id) ? playlist.id : nil
      }
    )
  }

  private func saveMembership() {
    for playlist in session.playlists {
      session.setVideo(
        video.id,
        in: playlist.id,
        isIncluded: selectedIDs.contains(playlist.id)
      )
    }
  }

  private func isIncluded(in playlistID: String) -> Bool {
    switch playlistID {
    case "favorites":
      return session.favoriteVideoIDs.contains(video.id)
    case "watch-later":
      return session.watchLaterVideoIDs.contains(video.id)
    default:
      return session.playlistVideoIDs[playlistID]?.contains(video.id) == true
    }
  }
}
