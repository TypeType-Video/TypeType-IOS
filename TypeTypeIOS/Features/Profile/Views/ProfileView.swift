import SwiftUI

struct ProfileView: View {
  @StateObject private var viewModel: ProfileViewModel

  init(coordinator: RootCoordinator) {
    _viewModel = StateObject(
      wrappedValue: ProfileViewModel(
        profileService: coordinator.dependencies.profileService,
        sessionProvider: { coordinator.currentSession }
      )
    )
  }

  var body: some View {
    Form {
      Section("Account") {
        LabeledContent("User ID", value: viewModel.userID)
      }

      Section("Public profile") {
        TextField("Public username", text: $viewModel.publicUsername)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
        TextField("Bio", text: $viewModel.bio, axis: .vertical)
          .lineLimit(4, reservesSpace: true)
      }

      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .font(.footnote)
          .foregroundStyle(.red)
      }

      if let infoMessage = viewModel.infoMessage {
        Text(infoMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section {
        Button(viewModel.isSaving ? "Saving..." : "Save profile") {
          Task { await viewModel.save() }
        }
        .disabled(viewModel.isSaving)
      }
    }
    .navigationTitle("Profile")
  }
}
