import Foundation

struct DemoPodcastEpisode: Identifiable, Hashable {
  let id: String
  let title: String
  let date: String
  let duration: String

  var video: DemoVideo {
    video(creator: "TypeType & PipePipe", artwork: defaultArtwork)
  }

  func video(creator: String, artwork: DemoArtwork) -> DemoVideo {
    DemoVideo(
      id: "podcast-\(id)",
      title: title,
      channel: creator,
      metadata: "\(date) · Podcast",
      duration: duration.replacingOccurrences(of: " min", with: ":00"),
      artwork: artwork,
      progress: nil
    )
  }

  private var defaultArtwork: DemoArtwork {
    id == "native-ios" ? .typeType : .pipePipe
  }

  static let all = [
    DemoPodcastEpisode(
      id: "sabr",
      title: "Why TypeType chose SABR",
      date: "Today",
      duration: "42 min"
    ),
    DemoPodcastEpisode(
      id: "native-ios",
      title: "Building a native iOS client",
      date: "Jul 18",
      duration: "36 min"
    ),
    DemoPodcastEpisode(
      id: "self-hosting",
      title: "A calmer self-hosted media home",
      date: "Jul 10",
      duration: "51 min"
    ),
    DemoPodcastEpisode(
      id: "dearrow",
      title: "DeArrow and calmer discovery",
      date: "Jul 2",
      duration: "28 min"
    ),
    DemoPodcastEpisode(
      id: "community",
      title: "Building with an open community",
      date: "Jun 24",
      duration: "47 min"
    ),
    DemoPodcastEpisode(
      id: "privacy",
      title: "Privacy without giving up convenience",
      date: "Jun 16",
      duration: "39 min"
    ),
  ]
}
