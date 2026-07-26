import SwiftUI

extension DemoPlaybackSettingsView {
  var subtitleSelection: Binding<String> {
    Binding(
      get: {
        session.preferences.subtitlesEnabled
          ? session.preferences.subtitleLanguage
          : "Off"
      },
      set: { value in
        session.setPreference(\.subtitlesEnabled, to: value != "Off")
        if value != "Off" {
          session.setPreference(\.subtitleLanguage, to: value)
        }
      }
    )
  }
}
