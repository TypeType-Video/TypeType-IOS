import Foundation

enum LocalizationCatalog {
  static let developmentLocalization = "en"
  static let supportedLocalizations = ["en", "fr"]

  static let criticalKeys = [
    "Home",
    "Subscriptions",
    "History",
    "Playlists",
    "More",
    "Settings",
    "Notifications",
    "Downloads",
    "Download",
    "Close",
    "Done",
    "Save",
    "Reset",
    "Cancel",
    "Delete",
    "Retry",
    "Try again",
    "Share",
    "Sign out",
    "Appearance",
    "Color scheme",
    "System",
    "Light",
    "Dark",
    "Playback",
    "Quality",
    "Video",
    "Automatic",
    "Tracks",
    "Audio",
    "Subtitles",
    "Language",
    "Chapters",
    "Current chapter",
    "Player options",
    "Minimize player",
    "Close player",
    "Player presentation",
    "Image mode",
    "Fit",
    "Crop",
    "Stretch",
    "Cinema mode",
    "Picture in Picture",
    "Available",
    "Unavailable",
    "Speed",
    "Normal",
    "Muted",
    "Loop video",
    "Autoplay next video",
    "Audio only",
    "Default",
    "Community enhancements",
    "Stream information",
    "Delivery",
    "Start download",
    "Creating download job",
    "Progress",
    "Open or save file",
    "Refresh downloads",
    "Manage stored data",
    "Loading settings",
    "Settings unavailable",
    "Downloaded media stays available.",
    "Retry instance connection",
  ]

  static func table(for localization: String) -> [String: String] {
    guard let path = Bundle.main.path(
      forResource: "Localizable",
      ofType: "strings",
      inDirectory: nil,
      forLocalization: localization
    ) else {
      return [:]
    }

    return NSDictionary(contentsOfFile: path) as? [String: String] ?? [:]
  }
}
