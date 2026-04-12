import SwiftUI

struct CreatePlaylistSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State private var name: String = ""
  @State private var description: String = ""
  let onCreate: (String, String) -> Void

  var body: some View {
    NavigationStack {
      Form {
        TextField("Name", text: $name)
        TextField("Description", text: $description, axis: .vertical)
          .lineLimit(2...5)
      }
      .navigationTitle("New playlist")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Create") {
            onCreate(name, description)
            dismiss()
          }
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }
}
