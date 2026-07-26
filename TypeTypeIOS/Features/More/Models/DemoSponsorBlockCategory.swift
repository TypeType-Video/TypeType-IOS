import SwiftUI

struct DemoSponsorBlockCategory: Identifiable {
  let id: String
  let title: String
  let detail: String
  let color: Color
  let defaultAction: String
}

enum DemoSponsorBlockCatalog {
  static let categories = [
    DemoSponsorBlockCategory(
      id: "sponsor",
      title: "Sponsored message",
      detail: "Paid promotion, sponsorship, or direct advertising.",
      color: Color(red: 0, green: 0.83, blue: 0),
      defaultAction: "Skip"
    ),
    DemoSponsorBlockCategory(
      id: "selfpromo",
      title: "Self-promotion",
      detail: "Merch, donations, or guest promotion.",
      color: .yellow,
      defaultAction: "Skip"
    ),
    DemoSponsorBlockCategory(
      id: "exclusive_access",
      title: "Exclusive access",
      detail: "Whole-video labels for subsidized access.",
      color: Color(red: 0, green: 0.54, blue: 0.36),
      defaultAction: "Mark"
    ),
    DemoSponsorBlockCategory(
      id: "interaction",
      title: "Interaction reminder",
      detail: "Reminders to like, subscribe, or follow.",
      color: .purple,
      defaultAction: "Skip"
    ),
    DemoSponsorBlockCategory(
      id: "poi_highlight",
      title: "Highlight",
      detail: "The main point most viewers are looking for.",
      color: .pink,
      defaultAction: "Mark"
    ),
    DemoSponsorBlockCategory(
      id: "intro",
      title: "Intermission or intro",
      detail: "Low-content pauses or repeated animations.",
      color: .cyan,
      defaultAction: "Skip"
    ),
    DemoSponsorBlockCategory(
      id: "outro",
      title: "Endcards or credits",
      detail: "Credits or end screens without useful conclusions.",
      color: .blue,
      defaultAction: "Skip"
    ),
    DemoSponsorBlockCategory(
      id: "preview",
      title: "Preview or recap",
      detail: "Clips repeated later in the video or series.",
      color: Color(red: 0, green: 0.56, blue: 0.84),
      defaultAction: "Skip"
    ),
    DemoSponsorBlockCategory(
      id: "filler",
      title: "Tangents or jokes",
      detail: "Aggressive skipping for non-essential tangents.",
      color: .indigo,
      defaultAction: "Skip"
    ),
    DemoSponsorBlockCategory(
      id: "chapter",
      title: "Chapter",
      detail: "Community chapters describing important sections.",
      color: .orange,
      defaultAction: "Mark"
    ),
    DemoSponsorBlockCategory(
      id: "music_offtopic",
      title: "Music: non-music",
      detail: "Non-musical sections in music videos.",
      color: Color(red: 1, green: 0.6, blue: 0),
      defaultAction: "Skip"
    ),
  ]

  static let defaultActions = Dictionary(
    uniqueKeysWithValues: categories.map { ($0.id, $0.defaultAction) }
  )
}
