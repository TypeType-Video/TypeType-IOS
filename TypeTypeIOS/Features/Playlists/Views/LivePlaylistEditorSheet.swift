import SwiftUI

struct LivePlaylistEditorSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State private var name: String
  @State private var description: String
  let title: String
  let actionTitle: String
  let onSave: (String, String) -> Void

  init(
    title: String,
    actionTitle: String,
    name: String = "",
    description: String = "",
    onSave: @escaping (String, String) -> Void
  ) {
    self.title = title
    self.actionTitle = actionTitle
    _name = State(initialValue: name)
    _description = State(initialValue: description)
    self.onSave = onSave
  }

  var body: some View {
    NavigationStack {
      Form {
        TextField("Name", text: $name)
          .textInputAutocapitalization(.sentences)
        TextField(
          "Description",
          text: $description,
          axis: .vertical
        )
        .lineLimit(3...6)
      }
        .liveThemeRepaint()
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(actionTitle) {
            onSave(
              name.trimmingCharacters(in: .whitespacesAndNewlines),
              description.trimmingCharacters(
                in: .whitespacesAndNewlines
              )
            )
          }
          .disabled(
            name.trimmingCharacters(in: .whitespacesAndNewlines)
              .isEmpty
          )
        }
      }
    }
    .presentationDetents([.medium])
  }
}
