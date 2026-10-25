import SwiftUI

struct LiveSettingsDiscoverySection: View {
  @Binding var settings: LiveSettings
  let services: [VideoService]

  var body: some View {
    Section {
      LiveOptionMenu(
        "Default landing page",
        selection: $settings.defaultLandingPage,
        options: [
          ("home", "Home"),
          ("subscriptions", "Subscriptions"),
          ("history", "History"),
          ("playlists", "Playlists"),
          ("watch-later", "Watch later"),
          ("favorites", "Favorites"),
        ]
      )
      LiveOptionMenu(
        "Default service",
        selection: $settings.defaultService,
        options: services.map { ($0.id, $0.name) }
      )
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
    } header: { Text("Interface and discovery").liveSectionHeader() }

    if settings.hideSubscriptionLiveStreams != nil {
      Section {
        Toggle(
          "Hide subscription live streams",
          isOn: Binding(
            get: { settings.hideSubscriptionLiveStreams ?? false },
            set: { settings.hideSubscriptionLiveStreams = $0 }
          )
        )
      } footer: {
        Text("Hide live streams from your subscription feed.").liveSectionSlotChrome()
      }
    }

    Section {
      Toggle("Enable DeArrow", isOn: $settings.deArrowEnabled)
      LiveOptionMenu(
        "Titles",
        selection: $settings.deArrowTitleMode,
        options: [("dearrow", "DeArrow"), ("original", "Original")]
      )
      LiveOptionMenu(
        "Thumbnails",
        selection: $settings.deArrowThumbnailMode,
        options: [
          ("dearrow_or_random", "DeArrow or random"),
          ("dearrow", "DeArrow"),
          ("random", "Random"),
          ("original", "Original"),
        ]
      )
      LiveOptionMenu(
        "Trust",
        selection: $settings.deArrowTrustMode,
        options: [("accepted", "Accepted"), ("locked", "Locked entries only")]
      )
    } header: { Text("DeArrow").liveSectionHeader() }
  }
}
