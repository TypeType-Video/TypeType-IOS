import AVFoundation
import Foundation

struct WatchPlaybackPreferences {
  let autoplay: Bool
  let volume: Float
  let muted: Bool
  let subtitlesEnabled: Bool
  let defaultSubtitleLanguage: String
  let defaultAudioLanguage: String
  let preferOriginalLanguage: Bool
  let defaultQuality: String

  init(settings: UserSettings) {
    autoplay = settings.autoplay
    volume = Float(max(0, min(1, settings.volume)))
    muted = settings.muted
    subtitlesEnabled = settings.subtitlesEnabled
    defaultSubtitleLanguage = settings.defaultSubtitleLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
    defaultAudioLanguage = settings.defaultAudioLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
    preferOriginalLanguage = settings.preferOriginalLanguage
    defaultQuality = settings.defaultQuality.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static let `default` = WatchPlaybackPreferences(settings: .default)
}

enum WatchPlaybackSelection {
  static func selectVideoURL(for stream: WatchStream, defaultQuality: String) -> URL? {
    let preferred = normalizedQuality(defaultQuality)
    if let preferred {
      let preferredCandidates = stream.videoStreams
        .filter { normalizedQuality($0.resolution) == preferred }
        .sorted(by: { qualityScore($0.resolution) > qualityScore($1.resolution) })
      if let selected = preferredCandidates.first,
        let url = URL(string: selected.url),
        selected.url.hasPrefix("http") {
        return url
      }
    }

    if let best = stream.videoStreams
      .sorted(by: { qualityScore($0.resolution) > qualityScore($1.resolution) })
      .first,
      let url = URL(string: best.url),
      best.url.hasPrefix("http") {
      return url
    }

    return stream.playbackURL
  }

  static func preferredSubtitleOption(
    from group: AVMediaSelectionGroup?,
    subtitlesEnabled: Bool,
    defaultSubtitleLanguage: String
  ) -> AVMediaSelectionOption? {
    guard let group else { return nil }
    guard subtitlesEnabled else { return nil }

    let preferred = defaultSubtitleLanguage.lowercased()
    if !preferred.isEmpty,
      let byLang = group.options.first(where: {
        ($0.extendedLanguageTag ?? "").lowercased().hasPrefix(preferred)
      }) {
      return byLang
    }

    if !preferred.isEmpty,
      let byLocale = group.options.first(where: {
        ($0.locale?.identifier ?? "").lowercased().hasPrefix(preferred)
      }) {
      return byLocale
    }

    return group.options.first
  }

  static func preferredAudioOption(
    from group: AVMediaSelectionGroup?,
    defaultAudioLanguage: String,
    preferOriginalLanguage: Bool
  ) -> AVMediaSelectionOption? {
    guard let group else { return nil }
    if preferOriginalLanguage,
      let original = group.options.first(where: {
        ($0.displayName).lowercased().contains("original")
      }) {
      return original
    }

    let preferred = defaultAudioLanguage.lowercased()
    if !preferred.isEmpty,
      let byLang = group.options.first(where: {
        ($0.extendedLanguageTag ?? "").lowercased().hasPrefix(preferred)
      }) {
      return byLang
    }

    if !preferred.isEmpty,
      let byLocale = group.options.first(where: {
        ($0.locale?.identifier ?? "").lowercased().hasPrefix(preferred)
      }) {
      return byLocale
    }

    return nil
  }

  private static func normalizedQuality(_ value: String) -> String? {
    let lower = value.lowercased()
    if lower.contains("2160") || lower.contains("4k") { return "2160" }
    if lower.contains("1440") { return "1440" }
    if lower.contains("1080") { return "1080" }
    if lower.contains("720") { return "720" }
    if lower.contains("480") { return "480" }
    if lower.contains("360") { return "360" }
    if lower.contains("240") { return "240" }
    if lower.contains("144") { return "144" }
    return nil
  }

  private static func qualityScore(_ value: String) -> Int {
    Int(normalizedQuality(value) ?? "0") ?? 0
  }
}
