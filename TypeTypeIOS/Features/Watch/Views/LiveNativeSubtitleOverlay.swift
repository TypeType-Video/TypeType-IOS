import SwiftUI

struct LiveNativeSubtitleOverlay: View {
  @ObservedObject var controller: LivePlayerController

  var body: some View {
    if let playback = controller.nativePlayback, !controller.nativeSubtitleCues.isEmpty {
      TimelineView(.animation(minimumInterval: 0.2, paused: controller.state != .playing)) { _ in
        if let cue = LiveWebVTT.cue(at: playback.player.currentTime, in: controller.nativeSubtitleCues) {
          Text(cue.text)
            .font(.subheadline.weight(.medium))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      .padding(.horizontal, 24)
      .padding(.bottom, 40)
      .allowsHitTesting(false)
      .accessibilityIdentifier("live.player.subtitles")
    }
  }
}
