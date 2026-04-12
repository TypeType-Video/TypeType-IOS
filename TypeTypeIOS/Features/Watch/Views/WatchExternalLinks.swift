import SwiftUI

struct WatchExternalLinks: View {
  let videoURL: String
  let uploaderURL: String

  var body: some View {
    HStack {
      if let source = URL(string: videoURL) {
        Link("Open Source", destination: source)
          .buttonStyle(.borderedProminent)
      }
      if let uploader = URL(string: uploaderURL), !uploaderURL.isEmpty {
        Link("Channel", destination: uploader)
          .buttonStyle(.bordered)
      }
    }
  }
}
