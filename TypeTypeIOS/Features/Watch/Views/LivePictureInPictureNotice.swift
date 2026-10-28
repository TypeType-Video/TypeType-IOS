import SwiftUI

/// Shown over the video surface while Picture in Picture is running: the
/// inline surface stays covered instead of rendering the video twice, and
/// the user can bring playback back into the app.
struct LivePictureInPictureNotice: View {
  @ObservedObject var pictureInPicture: LivePictureInPictureDriver

  var body: some View {
    if pictureInPicture.isEngaged {
      ZStack {
        Color.black
        VStack(spacing: 12) {
          Image(systemName: "pip")
            .font(.system(size: 34, weight: .medium))
            .foregroundStyle(.white)
          Text("Playing in Picture in Picture")
            .font(.headline)
            .foregroundStyle(.white)
          #if DEBUG
          Text(LivePictureInPictureDriver.lastTimingLog)
            .font(.caption2.monospaced())
            .foregroundStyle(.white.opacity(0.7))
          #endif
          Button("Show in Player") {
            pictureInPicture.bringInline()
          }
          .buttonStyle(.borderedProminent)
          .accessibilityIdentifier("live.player.pip.bringInline")
        }
        .padding(24)
      }
      .accessibilityIdentifier("live.player.pip.notice")
    }
  }
}

extension LivePlayerView {
  func overlayIcon(_ symbol: String) -> some View {
    Image(systemName: symbol)
      .font(.body.weight(.semibold))
      .foregroundStyle(.white)
      .frame(width: 38, height: 38)
      .background(.black.opacity(0.58), in: Circle())
      .overlay {
        Circle().stroke(.white.opacity(0.22), lineWidth: 0.5)
      }
  }
}
