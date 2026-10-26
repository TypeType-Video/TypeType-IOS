import SwiftUI

enum LiveAccentColor: String, Codable, CaseIterable, Identifiable {
  case red, blue, yellow, green, purple, violet, monochrome, system

  var id: String { rawValue }

  var title: String {
    switch self {
    case .red: return "Red"
    case .blue: return "Blue"
    case .yellow: return "Yellow"
    case .green: return "Green"
    case .purple: return "Purple"
    case .violet: return "Violet"
    case .monochrome: return "Monochrome"
    case .system: return "System"
    }
  }

  var color: Color {
    switch self {
    case .red: return Color(red: 1, green: 0.30, blue: 0.32)
    case .blue: return .blue
    case .yellow: return .yellow
    case .green: return .green
    case .purple: return .purple
    case .violet: return .indigo
    case .monochrome: return .primary
    case .system: return .accentColor
    }
  }
}

enum LiveAppearancePersonality: String, Codable, CaseIterable, Identifiable {
  case classic, manga
  var id: String { rawValue }
  var title: String { self == .classic ? "Classic" : "Manga" }
}

enum LiveAppearanceTheme: String, Codable, CaseIterable, Identifiable {
  case typetype, snow, nord, cream, forest, plum
  var id: String { rawValue }

  /// Tolerates old stores: the removed `dynamic` theme maps to Snow.
  init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    switch raw {
    case "dynamic":
      self = .snow
    default:
      self = LiveAppearanceTheme(rawValue: raw) ?? .typetype
    }
  }

  var title: String {
    switch self {
    case .typetype: return "TypeType"
    case .snow: return "Snow"
    case .nord: return "Nord"
    case .cream: return "Cream"
    case .forest: return "Forest"
    case .plum: return "Plum"
    }
  }
}

enum LiveAppearanceFont: String, Codable, CaseIterable, Identifiable {
  case system, expressive
  var id: String { rawValue }
  var title: String { self == .system ? "System" : "Expressive" }
}

enum LiveAppearanceMotion: String, Codable, CaseIterable, Identifiable {
  case full, subtle, off
  var id: String { rawValue }

  var title: String {
    switch self {
    case .full: return "Full"
    case .subtle: return "Subtle"
    case .off: return "Off"
    }
  }

  var duration: TimeInterval? {
    switch self {
    case .full: return 0.28
    case .subtle: return 0.16
    case .off: return 0
    }
  }
}

enum LiveMangaPaper: String, Codable, CaseIterable, Identifiable {
  case day, night, nord
  var id: String { rawValue }
  var title: String { rawValue.capitalized }
}

enum LiveMangaHeadlineMarker: String, Codable, CaseIterable, Identifiable {
  case none, stamp, speedLines
  var id: String { rawValue }

  var title: String {
    switch self {
    case .none: return "None"
    case .stamp: return "Stamp"
    case .speedLines: return "Speed lines"
    }
  }
}

struct LiveAppPreferences: Codable, Equatable {
  var accentColor = LiveAccentColor.red
  var appearancePersonality = LiveAppearancePersonality.classic
  var appearanceMode = LiveAppearanceMode.system
  var appearanceAmoled = false
  var appearanceTheme = LiveAppearanceTheme.typetype
  var appearanceFont = LiveAppearanceFont.system
  var appearanceMotion = LiveAppearanceMotion.subtle
  var mangaPaper = LiveMangaPaper.day
  var mangaHeadlineMarker = LiveMangaHeadlineMarker.stamp
  var mangaScreentone = true
  var mangaSpeedLines = true
  var mangaStarburst = true
  var mangaInkedIcons = true
  var mangaPanelTilt = false
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

  enum CodingKeys: String, CodingKey {
    case accentColor, appearancePersonality, appearanceMode, appearanceAmoled
    case appearanceTheme, appearanceFont, appearanceMotion, mangaPaper
    case mangaHeadlineMarker, mangaScreentone, mangaSpeedLines
    case mangaStarburst, mangaInkedIcons, mangaPanelTilt
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
    accentColor = try values.decodeIfPresent(
      LiveAccentColor.self, forKey: .accentColor
    ) ?? .red
    appearancePersonality = try values.decodeIfPresent(
      LiveAppearancePersonality.self, forKey: .appearancePersonality
    ) ?? .classic
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
    mangaPaper = try values.decodeIfPresent(
      LiveMangaPaper.self, forKey: .mangaPaper
    ) ?? .day
    mangaHeadlineMarker = try values.decodeIfPresent(
      LiveMangaHeadlineMarker.self, forKey: .mangaHeadlineMarker
    ) ?? .stamp
    mangaScreentone = try values.decodeIfPresent(
      Bool.self, forKey: .mangaScreentone
    ) ?? true
    mangaSpeedLines = try values.decodeIfPresent(
      Bool.self, forKey: .mangaSpeedLines
    ) ?? true
    mangaStarburst = try values.decodeIfPresent(
      Bool.self, forKey: .mangaStarburst
    ) ?? true
    mangaInkedIcons = try values.decodeIfPresent(
      Bool.self, forKey: .mangaInkedIcons
    ) ?? true
    mangaPanelTilt = try values.decodeIfPresent(
      Bool.self, forKey: .mangaPanelTilt
    ) ?? false
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

@MainActor
final class LiveAppPreferencesStore: ObservableObject {
  static let shared = LiveAppPreferencesStore()
  static let storageKey = "typetype.app-preferences.v1"

  @Published private(set) var preferences: LiveAppPreferences
  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    if let data = defaults.data(forKey: Self.storageKey),
      let decoded = try? JSONDecoder().decode(
        LiveAppPreferences.self,
        from: data
      ) {
      preferences = decoded
    } else if let rawValue = defaults.string(
      forKey: LiveAppearancePreference.storageKey
    ) {
      var migrated = LiveAppPreferences()
      migrated.appearanceMode = LiveAppearancePreference.mode(
        for: rawValue
      )
      preferences = migrated
    } else {
      preferences = LiveAppPreferences()
    }
  }

  func update(_ mutation: (inout LiveAppPreferences) -> Void) {
    var value = preferences
    mutation(&value)
    guard value != preferences else { return }
    preferences = value
    defaults.set(
      (try? JSONEncoder().encode(value)),
      forKey: Self.storageKey
    )
  }

  func binding<Value>(
    _ keyPath: WritableKeyPath<LiveAppPreferences, Value>
  ) -> Binding<Value> {
    Binding(
      get: { self.preferences[keyPath: keyPath] },
      set: { value in self.update { $0[keyPath: keyPath] = value } }
    )
  }
}
