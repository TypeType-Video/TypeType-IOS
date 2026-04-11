import Foundation

struct UserSettings: Codable {
  var defaultService: Int
  var defaultQuality: String
  var autoplay: Bool
  var volume: Double
  var muted: Bool
  var subtitlesEnabled: Bool
  var defaultSubtitleLanguage: String
  var defaultAudioLanguage: String
  var preferOriginalLanguage: Bool
  var recommendationPersonalizationEnabled: Bool

  static let `default` = UserSettings(
    defaultService: 0,
    defaultQuality: "1080p",
    autoplay: true,
    volume: 1.0,
    muted: false,
    subtitlesEnabled: false,
    defaultSubtitleLanguage: "",
    defaultAudioLanguage: "",
    preferOriginalLanguage: false,
    recommendationPersonalizationEnabled: true
  )
}
