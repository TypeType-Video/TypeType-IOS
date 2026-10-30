import AVFoundation
import SwiftUI
import UIKit

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
