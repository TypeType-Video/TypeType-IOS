import SwiftUI

struct DemoResetPasswordView: View {
  let preferredColorScheme: ColorScheme
  @Environment(\.dismiss) private var dismiss
  @State private var email = ""
  @State private var isSubmitting = false
  @State private var didSubmit = false
  @State private var resetToken = ""
  @State private var newPassword = ""
  @State private var confirmation = ""
  @State private var didReset = false

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Email address", text: $email)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .accessibilityIdentifier("demo.auth.reset.email")
        } header: { Text("Account").liveSectionHeader() } footer: {
          Text("A mock reset link will be created locally. No message is sent.").liveSectionSlotChrome()
        }

        if didSubmit {
          Section {
            Label(
              "Reset instructions prepared for \(normalizedEmail).",
              systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)
          }

          Section {
            TextField("Reset token", text: $resetToken)
              .textInputAutocapitalization(.characters)
            SecureField("New password", text: $newPassword)
            SecureField("Confirm password", text: $confirmation)
            if !confirmation.isEmpty && newPassword != confirmation {
              Text("Passwords do not match.")
                .foregroundStyle(.red)
            }
          } header: { Text("Complete reset").liveSectionHeader() } footer: {
            Text("The local token is prefilled so the complete Web flow can be exercised.").liveSectionSlotChrome()
          }
        }

        if didReset {
          Section {
            Label("Password updated locally.", systemImage: "checkmark.shield.fill")
              .foregroundStyle(.green)
          }
        }
      }
      .navigationTitle("Reset password")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(buttonTitle) {
            submit()
          }
          .disabled(!canSubmit || isSubmitting || didReset)
          .accessibilityIdentifier("demo.auth.reset.submit")
        }
      }
    }
    .tint(DemoTheme.accent)
    .preferredColorScheme(preferredColorScheme)
    .presentationDetents([.medium])
    .accessibilityIdentifier("demo.auth.reset.screen")
  }

  private var normalizedEmail: String {
    email.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func submit() {
    isSubmitting = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(450))
      isSubmitting = false
      if didSubmit {
        withAnimation(.snappy) {
          didReset = true
        }
      } else {
        resetToken = "LOCAL-4821"
        withAnimation(.snappy) {
          didSubmit = true
        }
      }
    }
  }

  private var buttonTitle: String {
    if isSubmitting {
      return didSubmit ? "Updating..." : "Preparing..."
    }
    return didSubmit ? "Update password" : "Continue"
  }

  private var canSubmit: Bool {
    if !didSubmit {
      return !normalizedEmail.isEmpty
    }
    return !resetToken.isEmpty
      && newPassword.count >= 8
      && newPassword == confirmation
  }
}
