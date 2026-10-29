import AVFoundation
import SwiftUI
import UIKit

/// Play/pause with instant icon feedback: this view observes the player
/// controller directly, so the symbol flips the moment the state changes.
struct MiniPlayPauseButton: View {
  @ObservedObject var controller: LivePlayerController
  let diameter: CGFloat

  var body: some View {
    Button {
      controller.togglePlayback()
    } label: {
      Image(systemName: controller.state == .playing ? "pause.fill" : "play.fill")
        .font(.system(size: diameter * 0.38, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: diameter, height: diameter)
        .pipGlassBackground()
    }
    .buttonStyle(.plain)
    .accessibilityLabel(controller.state == .playing ? "Pause" : "Play")
    .accessibilityIdentifier("live.miniplayer.playback")
  }
}

/// Renders the playing video in the mini player: the same AVPlayer can back
/// several layers, so the small preview shows live video while the full
/// surface is off screen. Audio-only keeps the poster instead.
struct LiveVideoPreviewLayer: UIViewRepresentable {
  let player: AVPlayer

  func makeUIView(context: Context) -> PlayerPreviewView {
    PlayerPreviewView(player: player)
  }

  func updateUIView(_ uiView: PlayerPreviewView, context: Context) {}
}

final class PlayerPreviewView: UIView {
  private let playerLayer = AVPlayerLayer()

  init(player: AVPlayer) {
    super.init(frame: .zero)
    backgroundColor = .clear
    playerLayer.player = player
    playerLayer.videoGravity = .resizeAspect
    layer.addSublayer(playerLayer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer.frame = bounds
  }
}
