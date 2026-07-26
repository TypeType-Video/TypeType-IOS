enum DemoAutoplayPolicy {
  enum Source {
    case playlist
    case recommendation
  }

  enum Presentation: Equatable {
    case none
    case immediate
    case countdown
  }

  static func presentation(
    autoplay: Bool,
    source: Source,
    skipsPlaylistScreen: Bool,
    countdownSeconds: Int
  ) -> Presentation {
    guard autoplay else { return .none }
    if countdownSeconds <= 0 {
      return .immediate
    }
    if source == .playlist && skipsPlaylistScreen {
      return .immediate
    }
    return .countdown
  }
}
