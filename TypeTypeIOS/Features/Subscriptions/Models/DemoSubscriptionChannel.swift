import Foundation

struct DemoSubscriptionChannel: Identifiable {
  let id: String
  let name: String
  let handle: String
  let followers: String
  let artwork: DemoArtwork
  let isNew: Bool
}

enum DemoSubscriptionCatalog {
  static let channels = [
    DemoSubscriptionChannel(
      id: "blender",
      name: "Blender Open Movies",
      handle: "@blender",
      followers: "2.1M followers",
      artwork: .television,
      isNew: true
    ),
    DemoSubscriptionChannel(
      id: "typetype",
      name: "TypeType",
      handle: "@typetype",
      followers: "18K followers",
      artwork: .typeType,
      isNew: true
    ),
    DemoSubscriptionChannel(
      id: "pipepipe",
      name: "PipePipe",
      handle: "@pipepipe",
      followers: "36K followers",
      artwork: .pipePipe,
      isNew: false
    ),
    DemoSubscriptionChannel(
      id: "open-media",
      name: "Open Media",
      handle: "@openmedia",
      followers: "94K followers",
      artwork: .bird,
      isNew: false
    ),
    DemoSubscriptionChannel(
      id: "self-hosted",
      name: "Self-Hosted Lab",
      handle: "@selfhosted",
      followers: "51K followers",
      artwork: .dog,
      isNew: false
    ),
  ]

  static let videos = [
    DemoMockCatalog.recommendations[3],
    DemoMockCatalog.recommendations[0],
    DemoMockCatalog.recommendations[1],
    DemoMockCatalog.recommendations[4],
  ]

  static func channelID(for video: DemoVideo) -> String? {
    channels.first {
      video.channel.localizedCaseInsensitiveContains(
        $0.name.split(separator: " ").first.map(String.init) ?? $0.name
      )
    }?.id
  }
}
