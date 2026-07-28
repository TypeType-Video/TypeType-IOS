import Foundation

extension LivePlayerController {
  var availableSubtitles: [LivePlaybackSubtitle] {
    stream?.subtitles ?? []
  }

  func applyLoadedSettings() {
    autoplayEnabled = settings.autoplay
    subtitlesEnabled = settings.subtitlesEnabled
    selectedSubtitleLanguage = settings.defaultSubtitleLanguage
    sponsorBlockEnabled =
      settings.sponsorBlockMode != LiveSponsorBlockMode.disabled.rawValue
    sponsorBlockMode = settings.sponsorBlockMode
    sponsorBlockCategoryActions = settings.sponsorBlockCategoryActions
    sponsorBlockMinimumDuration = settings.sponsorBlockMinimumDuration
    sponsorBlockMuteInsteadOfSkip = settings.sponsorBlockMuteInsteadOfSkip
    sponsorBlockShowCurrentSegment =
      settings.sponsorBlockShowCurrentSegment
    sponsorBlockShowChapters = settings.sponsorBlockShowChapters
    sponsorBlockShowFullVideoLabels =
      settings.sponsorBlockShowFullVideoLabels
    sponsorBlockManualSkipOnFullVideo =
      settings.sponsorBlockManualSkipOnFullVideo
    sponsorBlockSkipNonMusicOnlyOnMusicVideos =
      settings.sponsorBlockSkipNonMusicOnlyOnMusicVideos
    muted = settings.muted
    player.volume = Float(min(max(settings.volume, 0), 1))
    player.isMuted = muted || sponsorMutedRange != nil
    loopsPlayback = UserDefaults.standard.bool(
      forKey: Self.loopPreferenceKey
    )
  }

  func applySettings(_ settings: LiveSettings) {
    self.settings = settings
    handledSponsorSegments.removeAll()
    applyLoadedSettings()
    if let item = player.currentItem {
      configureSubtitles(for: item)
    }
  }

  func setAutoplay(_ enabled: Bool) {
    autoplayEnabled = enabled
    updateSettings { $0.autoplay = enabled }
  }

  func setLooping(_ enabled: Bool) {
    loopsPlayback = enabled
    UserDefaults.standard.set(
      enabled,
      forKey: Self.loopPreferenceKey
    )
  }

  func setMuted(_ enabled: Bool) {
    muted = enabled
    player.isMuted = enabled || sponsorMutedRange != nil
    updateSettings { $0.muted = enabled }
  }

  func setSubtitlesEnabled(_ enabled: Bool) {
    subtitlesEnabled = enabled
    updateSettings { $0.subtitlesEnabled = enabled }
    if let item = player.currentItem {
      configureSubtitles(for: item)
    }
  }

  func selectSubtitleLanguage(_ language: String) {
    selectedSubtitleLanguage = language
    updateSettings { $0.defaultSubtitleLanguage = language }
    if let item = player.currentItem {
      configureSubtitles(for: item)
    }
  }

  func setSponsorBlockEnabled(_ enabled: Bool) {
    sponsorBlockEnabled = enabled
    setSponsorBlockMode(
      enabled
        ? LiveSponsorBlockMode.autoSkip.rawValue
        : LiveSponsorBlockMode.disabled.rawValue
    )
  }

  func setSponsorBlockMode(_ mode: String) {
    guard LiveSponsorBlockMode(rawValue: mode) != nil else { return }
    sponsorBlockMode = mode
    sponsorBlockEnabled = mode != LiveSponsorBlockMode.disabled.rawValue
    handledSponsorSegments.removeAll()
    updateSettings { $0.sponsorBlockMode = mode }
  }

  func setSponsorBlockCategoryAction(
    _ action: String,
    category: String
  ) {
    guard ["auto_skip", "mark_only", "disabled"].contains(action) else {
      return
    }
    sponsorBlockCategoryActions[category] = action
    handledSponsorSegments.removeAll()
    updateSettings {
      $0.sponsorBlockCategoryActions[category] = action
    }
  }

  func setSponsorBlockMinimumDuration(_ seconds: Int) {
    let value = min(max(seconds, 0), 600)
    sponsorBlockMinimumDuration = value
    handledSponsorSegments.removeAll()
    updateSettings { $0.sponsorBlockMinimumDuration = value }
  }

  func setSponsorBlockMuteInsteadOfSkip(_ enabled: Bool) {
    sponsorBlockMuteInsteadOfSkip = enabled
    handledSponsorSegments.removeAll()
    if !enabled, sponsorMutedRange != nil {
      sponsorMutedRange = nil
      player.isMuted = settings.muted
    }
    updateSettings { $0.sponsorBlockMuteInsteadOfSkip = enabled }
  }

  private func updateSettings(
    _ mutation: (inout LiveSettings) -> Void
  ) {
    mutation(&settings)
    let value = settings
    Task { [settingsService] in
      _ = try? await settingsService.update(value)
    }
  }

  private static let loopPreferenceKey =
    "typetype.player.loop-playback"
}
