struct DemoSponsorBlockSegment {
  let category: String
  let start: Double
  let end: Double
  let isFullVideo: Bool
}

enum DemoSponsorBlockPolicy {
  static func isVisible(
    _ segment: DemoSponsorBlockSegment,
    action: String,
    minimumDuration: Int,
    showsFullVideoLabels: Bool
  ) -> Bool {
    guard action != "Hide" else { return false }
    guard segment.end - segment.start >= Double(minimumDuration) else {
      return false
    }
    return showsFullVideoLabels || !segment.isFullVideo
  }

  static func shouldAutoSkip(
    _ segment: DemoSponsorBlockSegment,
    action: String,
    minimumDuration: Int,
    manualFullVideoSkip: Bool,
    skipsNonMusicOnlyOnMusicVideos: Bool,
    isMusicVideo: Bool
  ) -> Bool {
    guard action == "Skip" else { return false }
    guard segment.end - segment.start >= Double(minimumDuration) else {
      return false
    }
    if segment.isFullVideo && manualFullVideoSkip {
      return false
    }
    if segment.category == "music_offtopic",
      skipsNonMusicOnlyOnMusicVideos,
      !isMusicVideo {
      return false
    }
    return true
  }
}
