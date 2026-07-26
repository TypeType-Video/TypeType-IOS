import SwiftUI
import UIKit

extension DemoAuthCard {
  var subtitle: String {
    if mode == .signIn {
      return "Use your account credentials to continue."
    }
    if !session.adminSettings.allowsRegistration {
      return "Registrations are currently closed by the instance administrator."
    }
    return "Use your email to create an account. You can sign in with email or username."
  }

  var buttonTitle: String {
    mode == .signIn ? "Sign in" : "Register"
  }

  var localLoginEnabled: Bool {
    session.adminSettings.allowsLocalLogin
  }

  var canSubmit: Bool {
    let hasCredentials =
      !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !password.isEmpty
    if mode == .signIn {
      return localLoginEnabled && hasCredentials
    }
    return localLoginEnabled
      && session.adminSettings.allowsRegistration
      && hasCredentials
      && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && email.contains("@")
      && password.count >= 8
  }

  func footerButton(
    _ title: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(title, action: action)
      .font(.footnote.weight(.medium))
      .foregroundStyle(palette.primaryText)
      .buttonStyle(.plain)
  }

  func submit() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil,
      from: nil,
      for: nil
    )
    isSubmitting = true
    statusMessage = nil
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(420))
      isSubmitting = false
      if email.localizedCaseInsensitiveContains("error") {
        statusIsError = true
        statusMessage = "The local mock rejected these credentials."
        return
      }
      statusIsError = false
      statusMessage =
        mode == .signIn
        ? "Mock session created locally."
        : "Mock account created locally."
      try? await Task.sleep(for: .milliseconds(650))
      onAuthenticated()
    }
  }
}
