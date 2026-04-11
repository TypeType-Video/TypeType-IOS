import SwiftUI

struct AuthGateView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel = AuthViewModel()

  var body: some View {
    NavigationStack {
      Form {
        Picker("Mode", selection: $viewModel.mode) {
          Text("Sign In").tag(AuthViewModel.Mode.signIn)
          Text("Register").tag(AuthViewModel.Mode.register)
        }
        .pickerStyle(.segmented)

        if viewModel.mode == .signIn {
          LoginFormView(email: $viewModel.email, password: $viewModel.password)
        } else {
          RegisterFormView(
            name: $viewModel.name,
            email: $viewModel.email,
            password: $viewModel.password
          )
        }

        if let errorMessage = viewModel.errorMessage {
          Section {
            Text(errorMessage)
              .font(.footnote)
              .foregroundStyle(.red)
          }
        }

        Section {
          Button(viewModel.isLoading ? "Please wait..." : "Continue") {
            Task { await viewModel.submit(using: coordinator) }
          }
          .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
        }
      }
      .navigationTitle(coordinator.selectedServer?.name ?? "Authentication")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Servers") {
            coordinator.state = .serverSetup
          }
        }
      }
    }
    .transition(.move(edge: .trailing).combined(with: .opacity))
  }
}
