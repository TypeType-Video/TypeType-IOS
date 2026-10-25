import SwiftUI

struct DemoPlaylistCreateSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State private var name = ""
  let onCreate: (String) -> Void

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Playlist name", text: $name)
            .textInputAutocapitalization(.sentences)
            .accessibilityIdentifier("demo.playlists.name")
        } footer: {
          Text("This playlist is stored only for the current mock session.").liveSectionSlotChrome()
        }
      }
      .navigationTitle("New playlist")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Create") {
            onCreate(name.trimmingCharacters(in: .whitespacesAndNewlines))
            dismiss()
          }
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          .accessibilityIdentifier("demo.playlists.create")
        }
      }
    }
    .presentationDetents([.medium])
  }
}
