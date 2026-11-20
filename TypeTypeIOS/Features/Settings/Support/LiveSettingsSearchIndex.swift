import Foundation

enum LiveSettingsSearchTarget: Hashable {
  case page(LiveSettingsPage)
  case playback, gestures, language, sponsorBlock, danmaku
}

struct LiveSettingsSearchEntry: Hashable, Identifiable {
  let title: String
  let place: String
  let target: LiveSettingsSearchTarget
  let words: [String]

  var id: String { "\(target)|\(title)" }
}

enum LiveSettingsSearchIndex {
  private static let sub: [(LiveSettingsSearchTarget, String, [String])] = [
    (.playback, "Playback", [
      "Autoplay next video", "Autoplay countdown", "Skip playlist autoplay screen", "Autoplay on open",
      "Hide upcoming playlist videos", "Default quality", "Default speed", "Preferred codec", "Audio-only playback",
      "Pause in background", "Start muted",
    ]),
    (.gestures, "Gestures", [
      "Brightness and volume swipe", "Swipe to seek", "Double-tap to seek", "Double-tap seek time",
      "Long-press to speed up", "Hold speed", "Accessible player controls",
    ]),
    (.language, "Language and captions", ["Enable subtitles by default", "Subtitle language", "Audio language", "Prefer original language"]),
    (.sponsorBlock, "SponsorBlock", [
      "Global behavior", "Minimum duration", "Show current segment", "Show SponsorBlock chapters",
      "Show full-video labels", "Manual skip for full-video labels", "Non-music only on music videos", "Mute instead of skip",
    ]),
    (.danmaku, "Bullet comments", ["Show bullet comments", "Danmaku size", "Danmaku speed"]),
  ]

  private static let onPages: [(LiveSettingsPage, [String])] = [
    (.appearance, ["Color scheme", "AMOLED black", "Font", "Motion"]),
    (.content, [
      "Default landing page", "Default service", "Hide Continue watching", "Hide home recommendations",
      "Hide related videos", "Hide shorts", "Hide comments and danmaku", "Hide subscription live streams",
      "Hide members-only videos", "Hide end screens", "Enable DeArrow", "Titles", "Thumbnails",
    ]),
    (.privacy, ["Save watch history"]),
    (.player, ["Animate GIFs in comments"]),
  ]

  static func entries(pages: [LiveSettingsPage]) -> [LiveSettingsSearchEntry] {
    var result: [LiveSettingsSearchEntry] = []
    for page in pages {
      result.append(entry(page.title, place: String(localized: "Settings"), target: .page(page), extra: [page.subtitle]))
    }
    let accounts = LiveSettingsPage.accounts
    result.append(entry(accounts.title, place: String(localized: "Settings"), target: .page(accounts), extra: [accounts.subtitle]))
    result.append(entry("Linked accounts", place: localized(accounts.title), target: .page(accounts), extra: ["Twitch", "YouTube", "BiliBili"]))
    for (page, titles) in onPages where pages.contains(page) {
      result += titles.map { entry($0, place: localized(page.title), target: .page(page)) }
    }
    if pages.contains(.player) {
      for (target, place, titles) in sub {
        result.append(entry(place, place: localized("Player"), target: target))
        result += titles.map { entry($0, place: "\(localized("Player")) › \(localized(place))", target: target) }
      }
    }
    return result
  }

  static func search(_ query: String, in entries: [LiveSettingsSearchEntry]) -> [LiveSettingsSearchEntry] {
    let needle = fold(query)
    guard !needle.isEmpty else { return [] }
    return entries
      .compactMap { entry -> (LiveSettingsSearchEntry, Int)? in
        let title = fold(entry.title)
        if title.hasPrefix(needle) { return (entry, 0) }
        if title.contains(needle) { return (entry, 1) }
        if entry.words.contains(where: { fold($0).contains(needle) }) { return (entry, 2) }
        return nil
      }
      .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.0.title.count < $1.0.title.count }
      .map(\.0)
  }

  private static func entry(_ english: String, place: String, target: LiveSettingsSearchTarget, extra: [String] = []) -> LiveSettingsSearchEntry {
    let title = localized(english)
    return LiveSettingsSearchEntry(title: title, place: place, target: target, words: [english] + extra + extra.map(localized))
  }

  private static func localized(_ english: String) -> String {
    String(localized: String.LocalizationValue(english))
  }

  private static func fold(_ text: String) -> String {
    text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
