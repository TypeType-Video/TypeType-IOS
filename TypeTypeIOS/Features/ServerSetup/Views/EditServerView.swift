import SwiftUI

struct EditServerView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: EditServerViewModel

  init(server: ServerProfile, coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(wrappedValue: EditServerViewModel(server: server))
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Server") {
          TextField("Name", text: $viewModel.serverName)
          TextField("Server URL", text: $viewModel.serverURL)
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            .autocorrectionDisabled()
        }

        if let errorMessage = viewModel.errorMessage {
          Section {
            Text(errorMessage)
              .font(.footnote)
              .foregroundStyle(.red)
          }
        }
      }
      .navigationTitle("Edit Server")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(viewModel.isSaving ? "Saving..." : "Save") {
            Task {
              let success = await viewModel.submit(using: coordinator)
              if success { dismiss() }
            }
          }
          .disabled(viewModel.serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
        }
      }
    }
  }
}
