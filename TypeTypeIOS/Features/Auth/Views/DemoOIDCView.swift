import SwiftUI

struct DemoOIDCView: View {
  let preferredColorScheme: ColorScheme
  let onAuthorized: () -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var provider = "TypeType SSO"
  @State private var email = "demo@typetype.video"
  @State private var isAuthorizing = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Image("TypeTypeLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 72, height: 72)
            .frame(maxWidth: .infinity)
          Text("Authorize TypeType")
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity)
          Text("This mock browser flow never contacts an identity provider.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }

        Section("Identity provider") {
          Picker("Provider", selection: $provider) {
            Text("TypeType SSO").tag("TypeType SSO")
            Text("Community ID").tag("Community ID")
            Text("Unavailable provider").tag("Unavailable provider")
          }
          TextField("Email", text: $email)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
        }

        Section {
          Button(action: authorize) {
            HStack {
              Spacer()
              if isAuthorizing {
                ProgressView()
              } else {
                Label("Allow and continue", systemImage: "checkmark.shield")
              }
              Spacer()
            }
          }
          .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || isAuthorizing)
          .accessibilityIdentifier("demo.oidc.authorize")
        }

        if let message = errorMessage {
          Section {
            Label(message, systemImage: "exclamationmark.triangle")
              .foregroundStyle(.red)
            Button("Back to sign in") {
              errorMessage = nil
              provider = "TypeType SSO"
            }
          }
        }
      }
      .navigationTitle("OpenID")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
    .tint(DemoTheme.accent)
    .preferredColorScheme(preferredColorScheme)
    .accessibilityIdentifier("demo.oidc.screen")
  }

  private func authorize() {
    isAuthorizing = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(600))
      if provider == "Unavailable provider" {
        isAuthorizing = false
        errorMessage = "Sign-in could not be completed."
        return
      }
      dismiss()
      onAuthorized()
    }
  }
}
