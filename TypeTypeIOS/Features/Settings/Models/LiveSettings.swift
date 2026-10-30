import Foundation

struct LiveCaptionStyles: Codable, Equatable {
  var fontFamily = ""
  var fontSize = ""
  var textColor = ""
  var textOpacity = ""
  var textShadow = ""
  var textBackground = ""
  var textBackgroundOpacity = ""
  var displayBackground = ""
  var displayBackgroundOpacity = ""

  private enum CodingKeys: String, CodingKey {
    case fontFamily, fontSize, textColor, textOpacity, textShadow
    case textBackground = "textBg"
    case textBackgroundOpacity = "textBgOpacity"
    case displayBackground = "displayBg"
    case displayBackgroundOpacity = "displayBgOpacity"
  }
}

struct LiveSettings: Codable, Equatable {
  var defaultService = 0
  var defaultQuality = "1080p"
  var defaultPlaybackSpeed: Double?
  var defaultLandingPage = "home"
  var autoplay = true
  var skipPlaylistAutoplayScreen = false
  var volume = 1.0
  var muted = false
  var subtitlesEnabled = false
  var defaultSubtitleLanguage = ""
  var defaultAudioLanguage = ""
  var captionStyles = LiveCaptionStyles()
  var preferOriginalLanguage = false
  var enableHighQualityPlayback = false
  var sponsorBlockMode = "auto_skip"
  var sponsorBlockCategoryActions = [
    "sponsor": "auto_skip",
    "selfpromo": "auto_skip",
    "exclusive_access": "mark_only",
    "interaction": "auto_skip",
    "poi_highlight": "mark_only",
    "intro": "auto_skip",
    "outro": "auto_skip",
    "preview": "auto_skip",
    "filler": "auto_skip",
    "chapter": "mark_only",
    "music_offtopic": "auto_skip",
  ]
  var sponsorBlockMinimumDuration = 0
  var sponsorBlockShowCurrentSegment = true
  var sponsorBlockShowChapters = false
  var sponsorBlockShowFullVideoLabels = true
  var sponsorBlockManualSkipOnFullVideo = true
  var sponsorBlockSkipNonMusicOnlyOnMusicVideos = false
  var sponsorBlockMuteInsteadOfSkip = false
  var hideHomeRecommendations = false
  var hideContinueWatching = false
  var hideRelatedVideos = false
  var hideComments = false
  var hideShorts = false
  var hideSubscriptionLiveStreams: Bool?
  var disableWatchHistory = false
  var deArrowEnabled = false
  var deArrowTitleMode = "dearrow"
  var deArrowThumbnailMode = "dearrow_or_random"
  var deArrowTrustMode = "accepted"
  var accessMode = "unrestricted"
}

enum LiveSponsorBlockMode: String, CaseIterable, Identifiable {
  case autoSkip = "auto_skip"
  case markOnly = "mark_only"
  case disabled

  var id: String { rawValue }

  var title: String {
    switch self {
    case .autoSkip: return "Skip"
    case .markOnly: return "Mark"
    case .disabled: return "Off"
    }
  }
}
