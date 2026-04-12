import SwiftUI

struct WatchFormatBadges: View {
  let stream: WatchStream

  var body: some View {
    HStack(spacing: 8) {
      Text(stream.streamType.uppercased())
      if stream.isShortFormContent {
        Text("SHORT")
      }
      if let quality = stream.videoStreams.first(where: { !$0.resolution.isEmpty })?.resolution {
        Text(quality)
      }
      if !stream.subtitles.isEmpty {
        Text("SUB")
      }
    }
    .font(.caption2.weight(.semibold))
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(TypeTypeColor.card)
    .clipShape(Capsule())
  }
}
