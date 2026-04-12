import SwiftUI

struct ResetPasswordView: View {
  @StateObject private var viewModel: ResetPasswordViewModel

  init(service: ResetPasswordServiceProtocol) {
    _viewModel = StateObject(wrappedValue: ResetPasswordViewModel(service: service))
  }

  var body: some View {
    Form {
      Section("Reset token") {
        TextField("Token", text: $viewModel.token)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
      }

      Section("New password") {
        SecureField("New password", text: $viewModel.newPassword)
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
        Button(viewModel.isSubmitting ? "Updating..." : "Update password") {
          Task { await viewModel.submit() }
        }
        .disabled(viewModel.isSubmitting || viewModel.token.isEmpty || viewModel.newPassword.isEmpty)
      }
    }
    .navigationTitle("Reset Password")
  }
}
