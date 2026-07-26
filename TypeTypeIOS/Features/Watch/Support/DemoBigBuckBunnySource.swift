import Foundation

enum DemoBigBuckBunnySource {
  static let videoURL: URL = {
    #if targetEnvironment(simulator)
    if let silentSimulatorCopy = Bundle.main.url(
      forResource: "BigBuckBunnyDemo-Silent",
      withExtension: "mp4"
    ) {
      return silentSimulatorCopy
    }
    #endif

    if let bundled = Bundle.main.url(
      forResource: "BigBuckBunnyDemo",
      withExtension: "mp4"
    ) {
      return bundled
    }

    var components = URLComponents()
    components.scheme = "https"
    components.host = "eyewiki-images.s3.us-east-va.perf.cloud.ovh.us"
    components.path =
      "/5/50/BigBuckBunny_640x360.m4v"
    return components.url ?? URL(fileURLWithPath: "/")
  }()

  static let projectURL: URL = {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "peach.blender.org"
    return components.url ?? videoURL
  }()

  static let blenderProjectsURL: URL = {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "www.blender.org"
    components.path = "/about/projects/"
    return components.url ?? videoURL
  }()

  static let title = "Big Buck Bunny — Blender Open Movie"
  static let channel = "Blender Open Movies"
  static let metadata = "Open movie · 2008 · CC BY 3.0"
}
