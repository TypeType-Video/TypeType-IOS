import SwiftUI

struct DemoSessionPreferences {
  var autoplay = true
  var autoplayCountdownSeconds = 10
  var skipPlaylistAutoplayScreen = false
  var backgroundAudio = false
  var audioOnlyPlayback = false
  var sponsorBlock = true
  var sponsorBlockMode = "Skip"
  var sponsorBlockCategoryActions =
    DemoSponsorBlockCatalog.defaultActions
  var sponsorBlockMinimumDuration = 0
  var sponsorBlockShowsCurrentSegment = true
  var sponsorBlockShowsChapters = false
  var sponsorBlockShowsFullVideoLabels = true
  var sponsorBlockManualFullVideoSkip = true
  var sponsorBlockMusicOnly = false
  var sponsorBlockMutesInsteadOfSkips = false
  var deArrow = false
  var deArrowTitleMode = "Community title"
  var deArrowThumbnailMode = "Community, then neutral frame"
  var deArrowTrustMode = "Accepted entries"
  var defaultQuality = "1080p"
  var playbackSpeed = "1×"
  var subtitleLanguage = "English"
  var subtitlesEnabled = false
  var captionFont = "System"
  var captionSize = "Medium"
  var captionColor = "White"
  var captionBackgroundOpacity = 0.72
  var audioGainPercent = 100
  var audioLanguage = "Original"
  var prefersOriginalLanguage = true
  var loopPlayback = false
  var cinemaMode = false
  var bulletComments = false
  var bulletCommentSpeed = 1.0
  var bulletCommentSize = 1.0
  var playerDemoState = "Normal"

  var defaultService = "YouTube"
  var landingPage = "home"
  var showsContinueWatching = true
  var showsRecommendations = true
  var showsRelated = true
  var loadsComments = true

  var appearanceMode = "Dark"
  var accent = "Coral"
  var tracksHistory = true

  var colorScheme: ColorScheme? {
    switch appearanceMode {
    case "Light":
      return .light
    case "Dark":
      return .dark
    default:
      return nil
    }
  }

  var accentColor: Color {
    switch accent {
    case "Blue":
      return .blue
    case "Purple":
      return .purple
    default:
      return Color(red: 1, green: 0.3, blue: 0.32)
    }
  }
}
