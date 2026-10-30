import Foundation

struct LiveSponsorBlockWindow: Equatable, Identifiable {
  let segment: LivePlaybackSponsorSegment
  let start: TimeInterval
  let end: TimeInterval
  let isFullVideo: Bool
  let action: String

  var id: String { segment.id }
  var duration: TimeInterval { end - start }
}

enum LiveSponsorBlockPolicy {
  static func visibleWindows(
    segments: [LivePlaybackSponsorSegment],
    settings: LiveSettings,
    duration: TimeInterval
  ) -> [LiveSponsorBlockWindow] {
    guard settings.sponsorBlockMode
      != LiveSponsorBlockMode.disabled.rawValue
    else {
      return []
    }
    return segments.compactMap {
      window(for: $0, settings: settings, duration: duration)
    }.filter {
      $0.action != "disabled"
        && $0.duration >= TimeInterval(
          max(settings.sponsorBlockMinimumDuration, 0)
        )
        && (settings.sponsorBlockShowFullVideoLabels || !$0.isFullVideo)
    }
  }

  static func window(
    for segment: LivePlaybackSponsorSegment,
    settings: LiveSettings,
    duration: TimeInterval
  ) -> LiveSponsorBlockWindow? {
    let normalizesMilliseconds =
      duration > 0 && segment.endTime > duration + 30
    let divisor = normalizesMilliseconds ? 1_000.0 : 1
    let start = max(segment.startTime / divisor, 0)
    let end = max(segment.endTime / divisor, start)
    guard end > start else { return nil }
    return LiveSponsorBlockWindow(
      segment: segment,
      start: start,
      end: end,
      isFullVideo: duration > 0
        && start <= 5
        && end >= duration * 0.9,
      action: settings.sponsorBlockCategoryActions[
        segment.category
      ] ?? "mark_only"
    )
  }

  static func shouldAutoSkip(
    _ window: LiveSponsorBlockWindow,
    settings: LiveSettings,
    streamCategory: String?
  ) -> Bool {
    guard settings.sponsorBlockMode
      == LiveSponsorBlockMode.autoSkip.rawValue,
      window.action == "auto_skip",
      window.duration >= TimeInterval(
        max(settings.sponsorBlockMinimumDuration, 0)
      )
    else {
      return false
    }
    if window.isFullVideo,
      settings.sponsorBlockManualSkipOnFullVideo {
      return false
    }
    if window.segment.category == "music_offtopic",
      settings.sponsorBlockSkipNonMusicOnlyOnMusicVideos,
      streamCategory?.lowercased() != "music" {
      return false
    }
    return true
  }

  static func title(for category: String) -> String {
    switch category {
    case "sponsor": return String(localized: "Sponsored message")
    case "selfpromo": return String(localized: "Self-promotion")
    case "exclusive_access": return String(localized: "Exclusive access")
    case "interaction": return String(localized: "Interaction reminder")
    case "poi_highlight": return String(localized: "Highlight")
    case "intro": return String(localized: "Intermission or intro")
    case "outro": return String(localized: "Endcards or credits")
    case "preview": return String(localized: "Preview or recap")
    case "filler": return String(localized: "Tangents or jokes")
    case "chapter": return String(localized: "Chapter")
    case "music_offtopic": return String(localized: "Music: non-music")
    default: return category
    }
  }
}

struct LiveSponsorBlockNotice: Equatable, Identifiable {
  let id = UUID()
  let category: String
  let muted: Bool
}
