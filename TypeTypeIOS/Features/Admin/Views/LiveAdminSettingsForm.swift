import SwiftUI

struct LiveAdminSettingsForm: View {
  @Binding var settings: LiveAdminSettings
  let message: String?

  var body: some View {
    Form {
      Section {
        TextField("Instance name", text: $settings.name)
        TextField(
          "Tagline",
          text: optionalBinding(\.tagline)
        )
        TextField(
          "Logo URL",
          text: optionalBinding(\.logoURL)
        )
        .keyboardType(.URL)
        .textInputAutocapitalization(.never)
        TextField(
          "Banner URL",
          text: optionalBinding(\.bannerURL)
        )
        .keyboardType(.URL)
        .textInputAutocapitalization(.never)
      } header: { Text("Branding").liveSectionHeader() }

      Section {
        Toggle("Allow registration", isOn: $settings.allowRegistration)
        Toggle("Allow guests", isOn: $settings.allowGuest)
        Toggle(
          "Require email verification",
          isOn: $settings.forceEmailVerification
        )
        Toggle("Local login", isOn: $settings.localLoginEnabled)
        Toggle("OIDC auto redirect", isOn: $settings.oidcAutoRedirect)
      } header: { Text("Authentication").liveSectionHeader() }

      Section {
        Toggle(
          "Active session visibility",
          isOn: $settings.activeSessionsEnabled
        )
        Toggle(
          "YouTube remote login",
          isOn: $settings.youtubeRemoteLoginEnabled
        )
        TextField(
          "Minimum Android version",
          text: optionalBinding(\.minimumAndroidClientVersion)
        )
        Picker("Content access", selection: $settings.accessMode) {
          Text("Unrestricted").tag("unrestricted")
          Text("Allow list").tag("allow_list")
        }
      } header: { Text("Services").liveSectionHeader() }

      if let message {
        Section {
          Label(message, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        }
      }
    }
      .liveThemedList()
      .id(DemoTheme.renderToken)
  }

  private func optionalBinding(
    _ keyPath: WritableKeyPath<LiveAdminSettings, String?>
  ) -> Binding<String> {
    Binding(
      get: { settings[keyPath: keyPath] ?? "" },
      set: { settings[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
    )
  }
}
