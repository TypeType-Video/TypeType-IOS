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
          ("home", "Home", .system("house")),
          ("subscriptions", "Subscriptions", .system("play.square.stack")),
          ("history", "History", .system("clock.arrow.circlepath")),
          ("playlists", "Playlists", .system("music.note.list")),
          ("watch-later", "Watch later", .system("clock")),
          ("favorites", "Favorites", .system("heart")),
        ],
        help: "The page TypeType opens on after sign-in."
      )
      if services.count > 1 {
        LiveOptionMenu(
          "Default service",
          selection: $settings.defaultService,
          options: services.map { ($0.id, $0.name, .service($0)) },
          help: "Where Home, Search and links open first."
        )
      }
    } header: {
      Text("Opening").liveSectionHeader()
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
        "Hide shorts",
        help: "Removes shorts from search results and related videos.",
        isOn: $settings.hideShorts
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
      Text("Hidden sections").liveSectionHeader()
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
      Text("DeArrow").liveSectionHeader()
    }
  }

  private var deArrowReason: LocalizedStringKey? {
    settings.deArrowEnabled ? nil : "Turn on DeArrow to use this."
  }
}
