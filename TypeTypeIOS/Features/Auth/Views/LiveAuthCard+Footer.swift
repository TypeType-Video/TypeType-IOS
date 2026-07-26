import SwiftUI

extension LiveAuthCard {
  var subtitle: String {
    if viewModel.mode == .signIn {
      return "Use your TypeType account for this instance."
    }
    if !viewModel.registrationAllowed {
      return "Registrations are currently closed."
    }
    return "Create an account with your email address."
  }

  var footer: some View {
    HStack {
      if viewModel.mode == .signIn {
        if viewModel.registrationAllowed {
          footerButton("Create account") {
            viewModel.mode = .register
          }
        }
        Spacer()
        footerButton("Use a reset token") {
          showsResetPassword = true
        }
      } else {
        Spacer()
        footerButton("Already registered? Sign in") {
          viewModel.mode = .signIn
        }
        Spacer()
      }
    }
  }

  func loadingLabel(_ title: String) -> some View {
    HStack(spacing: 9) {
      if viewModel.isLoading {
        ProgressView()
          .controlSize(.small)
      }
      Text(viewModel.isLoading ? "Please wait…" : title)
        .font(.subheadline.weight(.semibold))
    }
  }

  private func footerButton(
    _ title: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(title, action: action)
      .font(.footnote.weight(.medium))
      .foregroundStyle(palette.primaryText)
      .buttonStyle(.plain)
  }
}
