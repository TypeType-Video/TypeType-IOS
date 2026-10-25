import SwiftUI

struct LiveAdminAllowedItemEditor: View {
  @Environment(\.dismiss) private var dismiss
  let title: String
  let label: String
  let onSave: (String, String) async -> Bool
  @State private var url = ""
  @State private var name = ""
  @State private var isSaving = false

  var body: some View {
    NavigationStack {
      Form {
        TextField("\(label) URL", text: $url)
          .keyboardType(.URL)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
        TextField("\(label) name (optional)", text: $name)
      }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DemoTheme.background)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            isSaving = true
            Task {
              if await onSave(
                url.trimmingCharacters(in: .whitespacesAndNewlines),
                name.trimmingCharacters(in: .whitespacesAndNewlines)
              ) {
                dismiss()
              }
              isSaving = false
            }
          }
          .disabled(url.isEmpty || isSaving)
        }
      }
    }
  }
}
