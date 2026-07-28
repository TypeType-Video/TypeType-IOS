import SwiftUI

struct LiveSettingsDiscoverySection: View {
  @Binding var settings: LiveSettings
  let services: [VideoService]

  var body: some View {
    Section("Interface and discovery") {
      Picker(
        "Default landing page",
        selection: $settings.defaultLandingPage
      ) {
        Text("Home").tag("home")
        Text("Subscriptions").tag("subscriptions")
        Text("History").tag("history")
        Text("Playlists").tag("playlists")
        Text("Watch later").tag("watch-later")
        Text("Favorites").tag("favorites")
      }
      Picker("Default service", selection: $settings.defaultService) {
        ForEach(services) { service in
          Text(service.name)
            .tag(service.id)
        }
      }
      Toggle(
        "Hide Continue watching",
        isOn: $settings.hideContinueWatching
      )
      Toggle(
        "Hide home recommendations",
        isOn: $settings.hideHomeRecommendations
      )
      Toggle(
        "Hide related videos",
        isOn: $settings.hideRelatedVideos
      )
      Toggle("Hide comments and danmaku", isOn: $settings.hideComments)
    }

    Section("DeArrow") {
      Toggle("Enable DeArrow", isOn: $settings.deArrowEnabled)
      Picker("Titles", selection: $settings.deArrowTitleMode) {
        Text("DeArrow").tag("dearrow")
        Text("Original").tag("original")
      }
      Picker(
        "Thumbnails",
        selection: $settings.deArrowThumbnailMode
      ) {
        Text("DeArrow or random").tag("dearrow_or_random")
        Text("DeArrow").tag("dearrow")
        Text("Random").tag("random")
        Text("Original").tag("original")
      }
      Picker("Trust", selection: $settings.deArrowTrustMode) {
        Text("Accepted").tag("accepted")
        Text("Locked entries only").tag("locked")
      }
    }
  }
}
