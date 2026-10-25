import SwiftUI

struct LiveContentControlEditor: View {
  @Environment(\.dismiss) private var dismiss
  let kind: LiveContentControlKind
  let canCreateGlobal: Bool
  let onSave: (String, String, Bool) async -> Bool
  @State private var url = ""
  @State private var name = ""
  @State private var global = false
  @State private var isSaving = false

  var body: some View {
    NavigationStack {
      List {
        Section {
          TextField("URL", text: $url)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
          if kind != .blockedVideos {
            TextField("Name (optional)", text: $name)
          }
          if canCreateGlobal {
            Toggle("Apply globally", isOn: $global)
          }
        } footer: {
          Text("The server validates and normalizes supported URLs.").liveSectionSlotChrome()
        }
      }
        .liveThemedList()
      .id(DemoTheme.renderToken)
      .navigationTitle("Add \(kind.title.lowercased())")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            isSaving = true
            Task {
              if await onSave(url, name, global) {
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
