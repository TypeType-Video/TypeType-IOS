import SwiftUI

struct DemoChangePasswordView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var session: DemoSessionStore
  @State private var currentPassword = ""
  @State private var newPassword = ""
  @State private var confirmation = ""
  @State private var isSaving = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      Form {
        Section("Password") {
          SecureField("Current password", text: $currentPassword)
          SecureField("New password", text: $newPassword)
          SecureField("Confirm new password", text: $confirmation)
        }
        if let errorMessage {
          Section {
            Label(errorMessage, systemImage: "exclamationmark.circle")
              .foregroundStyle(.red)
          }
        }
        Section {
          Button(action: save) {
            HStack {
              Spacer()
              if isSaving {
                ProgressView()
              } else {
                Text("Update password")
              }
              Spacer()
            }
          }
          .disabled(!canSubmit || isSaving)
          .accessibilityIdentifier("demo.profile.password.save")
        } footer: {
          Text("The password is validated locally and never stored.")
        }
      }
      .navigationTitle("Change password")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
    .preferredColorScheme(session.preferences.colorScheme)
  }

  private var canSubmit: Bool {
    !currentPassword.isEmpty && newPassword.count >= 8 && confirmation.count >= 8
  }

  private func save() {
    guard newPassword == confirmation else {
      errorMessage = "The new passwords do not match."
      return
    }
    errorMessage = nil
    isSaving = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(550))
      dismiss()
    }
  }
}
