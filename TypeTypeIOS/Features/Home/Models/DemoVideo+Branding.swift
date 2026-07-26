extension DemoVideo {
  func branded(using preferences: DemoSessionPreferences) -> DemoVideo {
    guard preferences.deArrow else { return self }
    return DemoVideo(
      id: id,
      title: brandedTitle(using: preferences),
      channel: channel,
      metadata: metadata,
      duration: duration,
      artwork: brandedArtwork(using: preferences),
      progress: progress
    )
  }

  private func brandedTitle(
    using preferences: DemoSessionPreferences
  ) -> String {
    guard preferences.deArrowTitleMode != "Original title" else {
      return title
    }
    guard trustsCommunityEntry(using: preferences) else { return title }
    return Self.communityTitles[id] ?? title
  }

  private func brandedArtwork(
    using preferences: DemoSessionPreferences
  ) -> DemoArtwork {
    switch preferences.deArrowThumbnailMode {
    case "Original thumbnail":
      return artwork
    case "Neutral frame":
      return neutralArtwork
    case "Community only":
      guard trustsCommunityEntry(using: preferences) else { return artwork }
      return Self.communityArtwork[id] ?? artwork
    default:
      guard trustsCommunityEntry(using: preferences) else {
        return neutralArtwork
      }
      return Self.communityArtwork[id] ?? neutralArtwork
    }
  }

  private func trustsCommunityEntry(
    using preferences: DemoSessionPreferences
  ) -> Bool {
    preferences.deArrowTrustMode != "Locked entries only"
      || Self.lockedEntryIDs.contains(id)
  }

  private var neutralArtwork: DemoArtwork {
    let choices: [DemoArtwork] = [.television, .dog, .cat, .bird]
    let total = id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    return choices[total % choices.count]
  }

  private static let communityTitles = [
    "big-buck-bunny": "A giant rabbit chooses kindness",
    "typetype-design": "Designing TypeType without the noise",
    "pipepipe-sabr": "How SABR keeps playback resilient",
    "open-source-weekly": "Open media projects worth watching",
    "native-ios": "TypeType finally feels at home on iOS",
    "sabr-explained": "SABR, explained without the hype",
    "private-home": "Build your own calm video home",
    "big-buck-restored": "Big Buck Bunny, beautifully restored",
    "discovery": "Find great videos without being tracked",
    "subscriptions": "Make subscriptions feel calm again",
  ]

  private static let communityArtwork: [String: DemoArtwork] = [
    "big-buck-bunny": .dog,
    "typetype-design": .typeType,
    "pipepipe-sabr": .television,
    "open-source-weekly": .cat,
    "native-ios": .cat,
    "sabr-explained": .bird,
    "private-home": .television,
    "big-buck-restored": .bird,
    "discovery": .dog,
    "subscriptions": .typeType,
  ]

  private static let lockedEntryIDs: Set<String> = [
    "big-buck-bunny",
    "native-ios",
    "sabr-explained",
  ]
}
