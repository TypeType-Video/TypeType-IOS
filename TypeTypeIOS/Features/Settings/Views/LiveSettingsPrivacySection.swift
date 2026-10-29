import SwiftUI

struct LiveSettingsPrivacySection: View {
  @Binding var settings: LiveSettings

  var body: some View {
    Section {
      Toggle(
        "Save watch history",
        isOn: Binding(
          get: { !settings.disableWatchHistory },
          set: { settings.disableWatchHistory = !$0 }
        )
      ).liveRowFill()
      LabeledContent(
        "Content access",
        value: settings.accessMode == "allow_list"
          ? "Allow list"
          : "Unrestricted"
      )
    } header: { Text("Privacy").liveSectionHeader() } footer: {
      Text(
        "Content access is managed by the instance administrator."
      )
    }
  }
}
