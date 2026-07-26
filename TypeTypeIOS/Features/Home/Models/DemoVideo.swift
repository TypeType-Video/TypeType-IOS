import Foundation

struct DemoVideo: Identifiable, Hashable {
  let id: String
  let title: String
  let channel: String
  let metadata: String
  let duration: String
  let artwork: DemoArtwork
  let progress: Double?
}

enum DemoArtwork: String, Hashable {
  case television = "DemoPixelTV"
  case dog = "DemoPixelDog"
  case cat = "DemoPixelCat"
  case bird = "DemoPixelBird"
  case pipePipe = "DemoPipePipe"
  case typeType = "DemoTypeTypeIcon"
}
