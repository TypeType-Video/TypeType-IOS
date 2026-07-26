import SwiftUI

struct DemoVideoSettingsView: View {
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    Form {
      Section("Community enhancements") {
        NavigationLink {
          DemoSponsorBlockSettingsView()
        } label: {
          LabeledContent(
            "SponsorBlock",
            value: session.preferences.sponsorBlockMode
          )
        }

        Toggle("DeArrow titles and thumbnails", isOn: binding(\.deArrow))

        if session.preferences.deArrow {
          picker(
            "Titles",
            keyPath: \.deArrowTitleMode,
            values: ["Community title", "Original title"]
          )
          picker(
            "Thumbnails",
            keyPath: \.deArrowThumbnailMode,
            values: [
              "Community, then neutral frame",
              "Community only",
              "Neutral frame",
              "Original thumbnail",
            ]
          )
          picker(
            "Confidence",
            keyPath: \.deArrowTrustMode,
            values: ["Accepted entries", "Locked entries only"]
          )
        }
      }

      Section("Watch page") {
        Toggle("Autoplay next video", isOn: binding(\.autoplay))
        Toggle("Related videos", isOn: binding(\.showsRelated))
        Toggle("Comments and danmaku", isOn: binding(\.loadsComments))
      }
    }
    .navigationTitle("Video")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("demo.video-settings.screen")
  }

  private func picker(
    _ title: String,
    keyPath: WritableKeyPath<DemoSessionPreferences, String>,
    values: [String]
  ) -> some View {
    Picker(title, selection: binding(keyPath)) {
      ForEach(values, id: \.self) { Text($0).tag($0) }
    }
  }

  private func binding<Value>(
    _ keyPath: WritableKeyPath<DemoSessionPreferences, Value>
  ) -> Binding<Value> {
    Binding(
      get: { session.preferences[keyPath: keyPath] },
      set: { session.setPreference(keyPath, to: $0) }
    )
  }
}
