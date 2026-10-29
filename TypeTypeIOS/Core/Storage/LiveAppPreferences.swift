import SwiftUI

struct LiveAppPreferences: Codable, Equatable {
  var accentColor = LiveAccentColor.red
  /// The custom accent picked with the rightmost swatch (hex RGB).
  var customAccentHex: String? = nil
  var appearanceMode = LiveAppearanceMode.system
  var appearanceAmoled = false
  var appearanceTheme = LiveAppearanceTheme.typetype
  var appearanceFont = LiveAppearanceFont.system
  var appearanceMotion = LiveAppearanceMotion.subtle
  var playerDoubleTapSeekEnabled = true
  var playerDoubleTapSeekSeconds = 10
  var playerPreferredCodec = "recommended"
  var playerSwipeSeekEnabled = true
  var playerSwipeBrightnessVolumeEnabled = true
  var playerPlaybackBrightnessPercent: Int?
  var playerLongPressSpeedEnabled = true
  var playerAccessibleControlsEnabled = false
  var playerAutoplayEnabled = true
  var playerAutoplayCountdownSeconds = 10
  var playerAudioOnlyPlayback = false
  var playerPauseInBackground = false
  var danmakuEnabled = false
  var danmakuSpeed = 1.0
  var danmakuSize = 1.0

  var accent: Color {
    guard accentColor == .custom else { return accentColor.color }
    return customAccentHex.flatMap(Color.init(hex:)) ?? .accentColor
  }

  enum CodingKeys: String, CodingKey {
    case accentColor, customAccentHex, appearanceMode, appearanceAmoled
    case appearanceTheme, appearanceFont, appearanceMotion
    case playerDoubleTapSeekEnabled = "playerDoubleTapSeek"
    case playerDoubleTapSeekSeconds = "playerDoubleTapSeekSeconds"
    case playerPreferredCodec, playerSwipeSeekEnabled
    case playerSwipeBrightnessVolumeEnabled, playerPlaybackBrightnessPercent
    case playerLongPressSpeedEnabled, playerAccessibleControlsEnabled
    case playerAutoplayEnabled, playerAutoplayCountdownSeconds
    case playerAudioOnlyPlayback, playerPauseInBackground
    case danmakuEnabled, danmakuSpeed, danmakuSize
  }

  init() {}

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    customAccentHex = try values.decodeIfPresent(
      String.self, forKey: .customAccentHex
    )
    accentColor = try values.decodeIfPresent(
      LiveAccentColor.self, forKey: .accentColor
    ) ?? .red
    appearanceMode = try values.decodeIfPresent(
      LiveAppearanceMode.self, forKey: .appearanceMode
    ) ?? .system
    appearanceAmoled = try values.decodeIfPresent(
      Bool.self, forKey: .appearanceAmoled
    ) ?? false
    appearanceTheme = try values.decodeIfPresent(
      LiveAppearanceTheme.self, forKey: .appearanceTheme
    ) ?? .typetype
    appearanceFont = try values.decodeIfPresent(
      LiveAppearanceFont.self, forKey: .appearanceFont
    ) ?? .system
    appearanceMotion = try values.decodeIfPresent(
      LiveAppearanceMotion.self, forKey: .appearanceMotion
    ) ?? .subtle
    playerDoubleTapSeekEnabled = try values.decodeIfPresent(
      Bool.self, forKey: .playerDoubleTapSeekEnabled
    ) ?? true
    playerDoubleTapSeekSeconds = try values.decodeIfPresent(
      Int.self, forKey: .playerDoubleTapSeekSeconds
    ) ?? 10
    playerPreferredCodec = try values.decodeIfPresent(
      String.self, forKey: .playerPreferredCodec
    ) ?? "recommended"
    playerSwipeSeekEnabled = try values.decodeIfPresent(
      Bool.self, forKey: .playerSwipeSeekEnabled
    ) ?? true
    playerSwipeBrightnessVolumeEnabled = try values.decodeIfPresent(
      Bool.self, forKey: .playerSwipeBrightnessVolumeEnabled
    ) ?? true
    playerPlaybackBrightnessPercent = try values.decodeIfPresent(
      Int.self, forKey: .playerPlaybackBrightnessPercent
    )
    playerLongPressSpeedEnabled = try values.decodeIfPresent(
      Bool.self, forKey: .playerLongPressSpeedEnabled
    ) ?? true
    playerAccessibleControlsEnabled = try values.decodeIfPresent(
      Bool.self, forKey: .playerAccessibleControlsEnabled
    ) ?? false
    playerAutoplayEnabled = try values.decodeIfPresent(
      Bool.self, forKey: .playerAutoplayEnabled
    ) ?? true
    playerAutoplayCountdownSeconds = try values.decodeIfPresent(
      Int.self, forKey: .playerAutoplayCountdownSeconds
    ) ?? 10
    playerAudioOnlyPlayback = try values.decodeIfPresent(
      Bool.self, forKey: .playerAudioOnlyPlayback
    ) ?? false
    playerPauseInBackground = try values.decodeIfPresent(
      Bool.self, forKey: .playerPauseInBackground
    ) ?? false
    danmakuEnabled = try values.decodeIfPresent(
      Bool.self, forKey: .danmakuEnabled
    ) ?? false
    danmakuSpeed = try values.decodeIfPresent(
      Double.self, forKey: .danmakuSpeed
    ) ?? 1
    danmakuSize = try values.decodeIfPresent(
      Double.self, forKey: .danmakuSize
    ) ?? 1
  }
}
