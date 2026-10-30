import SwiftUI

struct LiveSettingsPrivacySection: View {
  @Binding var settings: LiveSettings

  var body: some View {
    LiveSection {
      LiveSettingToggle(
        "Save watch history",
        help: "Saves watched videos and where you stopped.",
        isOn: Binding(
          get: { !settings.disableWatchHistory },
          set: { settings.disableWatchHistory = !$0 }
        )
      )
      LabeledContent("Content access") {
        Text(settings.accessMode == "allow_list" ? "Allow list" : "Unrestricted")
      }
    } header: {
      Text("Privacy").liveSettingsHeader()
    } footer: {
      Text("Content access is managed by the instance administrator.").liveSettingsFooter()
    }
  }
}

struct LiveSettingsSessionSection: View {
  let service: LiveSessionActivityServiceProtocol
  @State private var name = ""

  var body: some View {
    LiveSection {
      HStack(spacing: 12) {
        Text("Device name")
          .layoutPriority(1)
        TextField("Device name", text: $name)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(.secondary)
          .submitLabel(.done)
          .onSubmit { save() }
      }
      .liveRowFill()
    } header: {
      Text("Active session").liveSettingsHeader()
    } footer: {
      Text(
        "While you are signed in, this instance sees a random installation ID, this name and the video playing. No hardware ID, email or network details are sent, and a failed report never stops playback."
      )
      .liveSettingsFooter()
    }
    .onAppear { name = service.deviceName }
    .onDisappear { save() }
  }

  private func save() {
    service.setDeviceName(name)
    name = service.deviceName
  }
}
