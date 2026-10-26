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
        Toggle("Allow registration", isOn: $settings.allowRegistration).liveRowFill()
        Toggle("Allow guests", isOn: $settings.allowGuest).liveRowFill()
        Toggle(
          "Require email verification",
          isOn: $settings.forceEmailVerification
        ).liveRowFill()
        Toggle("Local login", isOn: $settings.localLoginEnabled).liveRowFill()
        Toggle("OIDC auto redirect", isOn: $settings.oidcAutoRedirect).liveRowFill()
      } header: { Text("Authentication").liveSectionHeader() }

      Section {
        Toggle(
          "Active session visibility",
          isOn: $settings.activeSessionsEnabled
        ).liveRowFill()
        Toggle(
          "YouTube remote login",
          isOn: $settings.youtubeRemoteLoginEnabled
        ).liveRowFill()
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
      .liveThemeRepaint()
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
