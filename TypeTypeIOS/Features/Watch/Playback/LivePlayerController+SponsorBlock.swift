import Foundation

extension LivePlayerController {
  var sponsorBlockChapters: [LivePlaybackChapter] {
    guard sponsorBlockShowChapters else { return [] }
    return visibleSponsorBlockWindows.map { window in
      LivePlaybackChapter(
        title: LiveSponsorBlockPolicy.title(
          for: window.segment.category
        ),
        startTimeSeconds: Int(window.start.rounded(.down)),
        channelName: "SponsorBlock",
        url: nil,
        previewURL: nil
      )
    }
  }

  /// The chapter list shown in the player: real stream chapters plus the
  /// SponsorBlock-derived ones — the same union the page used before the
  /// page's chapter section went away.
  var displayedChapters: [LivePlaybackChapter] {
    (availableChapters + sponsorBlockChapters).sorted {
      $0.startTimeSeconds < $1.startTimeSeconds
    }
  }

  func canManuallySkipSponsorBlock(
    _ window: LiveSponsorBlockWindow
  ) -> Bool {
    guard let stream else { return false }
    return sponsorBlockMuteInsteadOfSkip
      || !LiveSponsorBlockPolicy.shouldAutoSkip(
        window,
        settings: settings,
        streamCategory: stream.category
      )
  }

  func setSponsorBlockShowCurrentSegment(_ enabled: Bool) {
    sponsorBlockShowCurrentSegment = enabled
    updateSponsorBlockSettings {
      $0.sponsorBlockShowCurrentSegment = enabled
    }
  }

  func setSponsorBlockShowChapters(_ enabled: Bool) {
    sponsorBlockShowChapters = enabled
    updateSponsorBlockSettings {
      $0.sponsorBlockShowChapters = enabled
    }
  }

  func setSponsorBlockShowFullVideoLabels(_ enabled: Bool) {
    sponsorBlockShowFullVideoLabels = enabled
    handledSponsorSegments.removeAll()
    updateSponsorBlockSettings {
      $0.sponsorBlockShowFullVideoLabels = enabled
    }
  }

  func setSponsorBlockManualSkipOnFullVideo(_ enabled: Bool) {
    sponsorBlockManualSkipOnFullVideo = enabled
    handledSponsorSegments.removeAll()
    updateSponsorBlockSettings {
      $0.sponsorBlockManualSkipOnFullVideo = enabled
    }
  }

  func setSponsorBlockMusicOnly(_ enabled: Bool) {
    sponsorBlockSkipNonMusicOnlyOnMusicVideos = enabled
    handledSponsorSegments.removeAll()
    updateSponsorBlockSettings {
      $0.sponsorBlockSkipNonMusicOnlyOnMusicVideos = enabled
    }
  }

  private func updateSponsorBlockSettings(
    _ mutation: (inout LiveSettings) -> Void
  ) {
    mutation(&settings)
    let value = settings
    Task { [settingsService] in
      do {
        _ = try await settingsService.update(value)
      } catch {
        AppLogger.network.failure("Saving SponsorBlock settings", error)
      }
    }
  }
}
