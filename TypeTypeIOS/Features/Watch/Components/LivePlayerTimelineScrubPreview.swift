import SwiftUI

// Slides across the track width minus its own, so the preview follows the thumb without leaving the track.
struct LivePlayerTimelineScrubPreview: View {
  let position: TimeInterval
  @ObservedObject var controller: LivePlayerController

  var body: some View {
    GeometryReader { proxy in
      let fraction = min(max(position / max(controller.duration, 1), 0), 1)
      LivePlayerSeekPreview(
        position: position,
        storyboard: LivePlaybackPreviewFrames.best(controller.stream?.previewFrames ?? [])
      )
      .offset(x: max(proxy.size.width - LivePlayerSeekPreview.width, 0) * fraction, y: -(proxy.size.height + 8))
      .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
    }
  }
}
