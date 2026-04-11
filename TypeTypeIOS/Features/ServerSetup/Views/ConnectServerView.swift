import SwiftUI

struct ConnectServerView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel = ConnectServerViewModel()

  var body: some View {
    NavigationStack {
      Form {
        Section("Server") {
          TextField("Name (optional)", text: $viewModel.serverName)
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
      .navigationTitle("Add Server")
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
