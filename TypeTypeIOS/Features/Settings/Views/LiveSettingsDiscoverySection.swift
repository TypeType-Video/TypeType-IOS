import SwiftUI

struct LiveSettingsDiscoverySection: View {
  @Binding var settings: LiveSettings
  let services: [VideoService]

  var body: some View {
    LiveSection {
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
        ],
        help: "The page TypeType opens on after sign-in."
      )
      if services.count > 1 {
        LiveSettingsServicePicker(selection: $settings.defaultService, services: services)
      }
    } header: {
      Text("Opening").liveSettingsHeader()
    }
    LiveSection {
      LiveSettingToggle(
        "Hide Continue watching",
        help: "Removes videos in progress from the home page.",
        isOn: $settings.hideContinueWatching
      )
      LiveSettingToggle(
        "Hide home recommendations",
        help: "Removes personalized recommendations from the home page.",
        isOn: $settings.hideHomeRecommendations
      )
      LiveSettingToggle(
        "Hide related videos",
        help: "Removes suggestions from the watch page.",
        isOn: $settings.hideRelatedVideos
      )
      LiveSettingToggle(
        "Hide comments and danmaku",
        help: "Stops loading comments and bullet comments.",
        isOn: $settings.hideComments
      )
      if settings.hideSubscriptionLiveStreams != nil {
        LiveSettingToggle(
          "Hide subscription live streams",
          help: "Removes live and upcoming streams from your subscriptions.",
          isOn: Binding(
            get: { settings.hideSubscriptionLiveStreams ?? false },
            set: { settings.hideSubscriptionLiveStreams = $0 }
          )
        )
      }
    } header: {
      Text("Hidden sections").liveSettingsHeader()
    }
    LiveSection {
      LiveSettingToggle(
        "Enable DeArrow",
        help: "Community-written titles and representative thumbnails for YouTube videos.",
        isOn: $settings.deArrowEnabled
      )
      LiveOptionMenu(
        "Titles",
        selection: $settings.deArrowTitleMode,
        options: [("dearrow", "DeArrow"), ("original", "Original")],
        help: "The title shown for YouTube videos.",
        disabledReason: deArrowReason
      )
      LiveOptionMenu(
        "Thumbnails",
        selection: $settings.deArrowThumbnailMode,
        options: [
          ("dearrow_or_random", "DeArrow or random"),
          ("dearrow", "DeArrow"),
          ("random", "Random"),
          ("original", "Original"),
        ],
        help: "The image shown for YouTube videos.",
        disabledReason: deArrowReason
      )
      LiveOptionMenu(
        "Trust",
        selection: $settings.deArrowTrustMode,
        options: [("accepted", "Accepted"), ("locked", "Locked entries only")],
        help: "Which community entries are used.",
        disabledReason: deArrowReason
      )
    } header: {
      Text("DeArrow").liveSettingsHeader()
    }
  }

  private var deArrowReason: LocalizedStringKey? {
    settings.deArrowEnabled ? nil : "Turn on DeArrow to use this."
  }
}
