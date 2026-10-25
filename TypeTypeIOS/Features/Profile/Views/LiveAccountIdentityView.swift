import SwiftUI

struct LiveAccountIdentityView: View {
  @StateObject private var viewModel: LiveAccountIdentityViewModel

  init(service: LiveProfileServiceProtocol) {
    _viewModel = StateObject(
      wrappedValue: LiveAccountIdentityViewModel(service: service)
    )
  }

  var body: some View {
    content
      .navigationTitle("Account identity")
      .navigationBarTitleDisplayMode(.inline)
      .task { await viewModel.prepare() }
      .alert("Account", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .accessibilityIdentifier("live.account-identity.screen")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView("Loading account")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView(
        "Account unavailable",
        systemImage: "person.crop.circle.badge.exclamationmark",
        description: Text(message)
      )
    case .loaded:
      Form {
        if viewModel.managedByOIDC {
          Section {
            Label(
              "This identity is managed by your OIDC provider.",
              systemImage: "building.2"
            )
          }
        }
        Section {
          TextField("Name", text: $viewModel.name)
            .textContentType(.name)
          TextField("Email", text: $viewModel.email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
          SecureField(
            "Current password",
            text: $viewModel.currentPassword
          )
          .textContentType(.password)
        } header: { Text("Identity").liveSectionHeader() }
        Section {
          Button {
            Task { await viewModel.save() }
          } label: {
            if viewModel.isSaving {
              ProgressView().frame(maxWidth: .infinity)
            } else {
              Text("Save identity").frame(maxWidth: .infinity)
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(
            viewModel.managedByOIDC
              || viewModel.isSaving
              || viewModel.email.isEmpty
              || viewModel.name.isEmpty
              || viewModel.currentPassword.isEmpty
          )
        }
        if let message = viewModel.message {
          Section {
            Label(message, systemImage: "checkmark.circle.fill")
              .foregroundStyle(.green)
          }
        }
      }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DemoThemeBackground())
      .id(DemoTheme.renderToken)
    }
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
