import Foundation

extension LivePlayerController {
  var availableSubtitles: [LivePlaybackSubtitle] {
    stream?.subtitles ?? []
  }

  var availableChapters: [LivePlaybackChapter] {
    (stream?.chapters ?? []).sorted {
      $0.startTimeSeconds < $1.startTimeSeconds
    }
  }

  var currentChapter: LivePlaybackChapter? {
    let index = LivePlaybackChapterNavigator.currentIndex(
      in: availableChapters,
      at: position
    )
    guard let index else { return nil }
    return availableChapters[index]
  }

  func applyLoadedSettings() {
    autoplayEnabled = settings.autoplay
      && LiveAppPreferencesStore.shared.preferences.playerAutoplayEnabled
    let serverPlaybackSpeed = settings.defaultPlaybackSpeed ?? 1
    if serverPlaybackSpeed != 1,
      UserDefaults.standard.object(
        forKey: Self.playbackRatePreferenceKey
      ) == nil {
      playbackRate = Self.normalizePlaybackRate(
        Float(serverPlaybackSpeed)
      )
    }
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
    setOutputVolume(Float(min(max(settings.volume, 0), 1)))
    setOutputMuted(muted || sponsorMutedRange != nil)
    loopsPlayback = UserDefaults.standard.bool(
      forKey: Self.loopPreferenceKey
    )
    playbackRate = Self.loadPlaybackRate()
    player.defaultRate = playbackRate
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
    setOutputMuted(enabled || sponsorMutedRange != nil)
    updateSettings { $0.muted = enabled }
  }

  func setImageMode(_ mode: LivePlayerImageMode) {
    imageMode = mode
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
      setOutputMuted(settings.muted)
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

  nonisolated static let playbackRatePreferenceKey =
    "typetype.player.playback-rate"

  nonisolated static func normalizePlaybackRate(_ rate: Float) -> Float {
    min(max(rate, 0.25), 4)
  }

  nonisolated static func loadPlaybackRate(
    defaults: UserDefaults = .standard
  ) -> Float {
    guard defaults.object(forKey: playbackRatePreferenceKey) != nil else {
      return 1
    }
    return normalizePlaybackRate(Float(
      defaults.double(forKey: playbackRatePreferenceKey)
    ))
  }

  nonisolated static func savePlaybackRate(
    _ rate: Float,
    defaults: UserDefaults = .standard
  ) {
    defaults.set(
      Double(normalizePlaybackRate(rate)),
      forKey: playbackRatePreferenceKey
    )
  }
}
