import SwiftUI

struct LiveAdminUserView: View {
  let currentUserID: String
  let accessService: LiveAdminAccessServiceProtocol
  @StateObject private var viewModel: LiveAdminUserViewModel
  @State private var confirmsSuspension = false
  @State private var confirmsReset = false

  init(
    user: LiveAdminUser,
    currentUserID: String,
    service: LiveAdminServiceProtocol,
    accessService: LiveAdminAccessServiceProtocol
  ) {
    self.currentUserID = currentUserID
    self.accessService = accessService
    _viewModel = StateObject(
      wrappedValue: LiveAdminUserViewModel(
        user: user,
        service: service
      )
    )
  }

  var body: some View {
    Form {
      Section {
        TextField("Name", text: $viewModel.name)
        TextField("Email", text: $viewModel.email)
          .keyboardType(.emailAddress)
          .textInputAutocapitalization(.never)
        Button("Save identity") {
          Task { await viewModel.saveIdentity() }
        }
        .disabled(viewModel.isBusy)
      } header: { Text("Identity").liveSectionHeader() }

      Section {
        Picker("Role", selection: $viewModel.role) {
          Text("User").tag("user")
          Text("Moderator").tag("moderator")
          Text("Admin").tag("admin")
        }
        Button("Save role") {
          Task { await viewModel.saveRole() }
        }
        .disabled(isCurrentUser || viewModel.isBusy)
        LabeledContent(
          "Content access",
          value: viewModel.user.accessMode == "allow_list"
            ? "Allow list"
            : "Unrestricted"
        )
        LabeledContent(
          "Email",
          value: viewModel.user.verified ? "Verified" : "Unverified"
        )
        NavigationLink("Configure allow list") {
          LiveAdminUserAccessView(
            userID: viewModel.user.id,
            service: accessService
          )
        }
      } header: { Text("Permissions").liveSectionHeader() }

      Section {
        Button(
          viewModel.user.suspended ? "Restore user" : "Suspend user",
          role: viewModel.user.suspended ? nil : .destructive
        ) {
          confirmsSuspension = true
        }
        .disabled(isCurrentUser || viewModel.isBusy)
        .liveConfirmPopover(
          isPresented: $confirmsSuspension,
          title: viewModel.user.suspended ? "Restore user?" : "Suspend user?",
          confirmTitle: viewModel.user.suspended ? "Restore" : "Suspend",
          destructive: !viewModel.user.suspended
        ) {
          Task { await viewModel.toggleSuspended() }
        }
        Button("Create password reset token") {
          confirmsReset = true
        }
        .disabled(viewModel.isBusy)
        .liveConfirmPopover(
          isPresented: $confirmsReset,
          title: "Create token?",
          message: "The reset token is shown in diagnostics logs and expires after 15 minutes.",
          confirmTitle: "Create token",
          destructive: false
        ) {
          Task { await viewModel.generateResetToken() }
        }
      } header: { Text("Security").liveSectionHeader() }

      if let token = viewModel.resetToken {
        Section {
          Text(token)
            .font(.caption.monospaced())
            .textSelection(.enabled)
          Text("This token is sensitive and should only be shared securely.")
            .font(.caption)
            .foregroundStyle(.secondary)
        } header: { Text("Password reset token").liveSectionHeader() }
      }

      if let message = viewModel.message {
        Section {
          Label(message, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        }
      }
    }
      .liveGroupedList()
    .navigationTitle(viewModel.user.name)
    .navigationBarTitleDisplayMode(.inline)
    .alert("Administration", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .accessibilityIdentifier("live.admin.user-detail")
  }

  private var isCurrentUser: Bool {
    viewModel.user.id == currentUserID
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
