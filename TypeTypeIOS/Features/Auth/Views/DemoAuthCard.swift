import SwiftUI

struct DemoAuthCard: View {
  @EnvironmentObject var session: DemoSessionStore
  @Binding var mode: AuthMode
  @Binding var name: String
  @Binding var email: String
  @Binding var password: String
  let isLight: Bool
  let onAuthenticated: () -> Void
  @State var isSubmitting = false
  @State var statusMessage: String?
  @State var statusIsError = false
  @State var presentsResetPassword = false
  @State var presentsOIDC = false
  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      heading

      if localLoginEnabled {
        VStack(spacing: 12) {
          if mode == .register {
            AuthField(
              placeholder: "Name",
              kind: .name,
              palette: palette,
              text: $name
            )
          }
          AuthField(
            placeholder: "Email or username",
            kind: .email,
            palette: palette,
            text: $email
          )
          AuthField(
            placeholder: "Password",
            kind: .password,
            palette: palette,
            text: $password
          )
        }
      } else {
        Text("Local sign-in is disabled. Continue with OpenID.")
          .font(.subheadline)
          .foregroundStyle(palette.secondaryText)
      }
      if let statusMessage {
        Label(
          statusMessage,
          systemImage: statusIsError
            ? "exclamationmark.triangle.fill"
            : "checkmark.circle.fill"
        )
          .font(.footnote)
          .foregroundStyle(statusIsError ? Color.red : Color.green)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
      if localLoginEnabled {
        primaryButton
      }
      DemoOIDCButton(palette: palette) {
        presentsOIDC = true
      }
      if localLoginEnabled {
        footer
      }
    }
    .padding(24)
    .frame(maxWidth: 448)
    .background(palette.cardSurface)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(palette.border, lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.38), radius: 28, y: 14)
    .animation(.snappy(duration: 0.28), value: mode)
    .animation(.easeOut(duration: 0.2), value: statusMessage)
    .onChange(of: mode) {
      statusMessage = nil
      statusIsError = false
    }
    .sheet(isPresented: $presentsResetPassword) {
      DemoResetPasswordView(
        preferredColorScheme: isLight ? .light : .dark
      )
    }
    .sheet(isPresented: $presentsOIDC) {
      DemoOIDCView(
        preferredColorScheme: isLight ? .light : .dark,
        onAuthorized: onAuthenticated
      )
    }
    .onAppear {
      if session.adminSettings.redirectsToOIDC {
        presentsOIDC = true
      }
    }
  }

  private var heading: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(mode == .signIn ? "Sign in" : "Create account")
        .font(.title3.weight(.semibold))
        .foregroundStyle(palette.primaryText)
      Text(subtitle)
        .font(.subheadline)
        .foregroundStyle(palette.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var primaryButton: some View {
    Button(action: submit) {
      HStack(spacing: 9) {
        if isSubmitting {
          ProgressView()
            .controlSize(.small)
        }
        Text(isSubmitting ? "Please wait..." : buttonTitle)
          .font(.subheadline.weight(.semibold))
      }
      .foregroundStyle(palette.buttonText)
      .frame(maxWidth: .infinity)
      .frame(minHeight: 48)
      .background(palette.buttonSurface.opacity(canSubmit ? 0.94 : 0.48))
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(!canSubmit || isSubmitting)
    .accessibilityIdentifier("demo.auth.submit")
  }

  @ViewBuilder
  private var footer: some View {
    if mode == .signIn {
      HStack {
        if session.adminSettings.allowsRegistration {
          footerButton("Create account") {
            mode = .register
          }
        } else {
          Text("Registrations closed")
            .font(.footnote)
            .foregroundStyle(palette.secondaryText)
        }
        Spacer()
        footerButton("Reset password") {
          presentsResetPassword = true
        }
      }
    } else {
      HStack(spacing: 4) {
        Text("Already have an account?")
          .foregroundStyle(palette.secondaryText)
        footerButton("Sign in") {
          mode = .signIn
        }
      }
      .frame(maxWidth: .infinity)
    }
  }

  var palette: AuthPalette {
    AuthPalette(isLight: isLight)
  }
}
