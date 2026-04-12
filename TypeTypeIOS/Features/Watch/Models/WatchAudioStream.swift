import Foundation

struct WatchAudioStream: Decodable {
  let url: String
  let format: String
  let quality: String?
  let audioTrackName: String?
  let audioLocale: String?
}
