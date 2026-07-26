import Foundation

struct DemoDownloadItem: Identifiable {
  let id: String
  let title: String
  let artwork: DemoArtwork
  var progress: Double
  var phase: String
  var errorMessage: String?

  init(
    id: String,
    title: String,
    artwork: DemoArtwork,
    progress: Double,
    phase: String? = nil,
    errorMessage: String? = nil
  ) {
    self.id = id
    self.title = title
    self.artwork = artwork
    self.progress = progress
    self.phase = phase ?? (progress >= 1 ? "ready" : "paused")
    self.errorMessage = errorMessage
  }

  var status: String {
    switch phase {
    case "ready":
      return "Ready offline"
    case "running":
      return "\(Int(progress * 100))% · downloading and packaging"
    case "cancelled":
      return "Cancelled · clear or retry"
    case "failed":
      return errorMessage ?? "Download failed"
    default:
      return "\(Int(progress * 100))% · paused"
    }
  }

  static let initial = [
    DemoDownloadItem(
      id: "big-buck-bunny",
      title: "Big Buck Bunny",
      artwork: .television,
      progress: 1
    ),
    DemoDownloadItem(
      id: "sabr-explained",
      title: "SABR explained",
      artwork: .pipePipe,
      progress: 0.42,
      phase: "running"
    ),
    DemoDownloadItem(
      id: "private-home",
      title: "Build a private video home",
      artwork: .dog,
      progress: 1
    ),
    DemoDownloadItem(
      id: "storage-check",
      title: "Offline storage check",
      artwork: .bird,
      progress: 0.08,
      phase: "failed",
      errorMessage: "Insufficient storage · free space and retry"
    ),
  ]
}
