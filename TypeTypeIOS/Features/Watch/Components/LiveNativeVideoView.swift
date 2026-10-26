import AVFoundation
import SwiftUI

struct LiveNativeVideoView: UIViewRepresentable {
  let playback: LiveNativePlayback
  let controller: LivePlayerController
  var onSwipeAdjustment: ((PlayerSwipeAdjustmentEvent) -> Void)? = nil
  var onHorizontalSeek: ((PlayerHorizontalSeekEvent) -> Void)? = nil

  func makeCoordinator() -> LivePlayerLayerCoordinator {
    LivePlayerLayerCoordinator(controller: controller)
  }

  func makeUIView(context: Context) -> LiveNativeVideoHostView {
    let view = LiveNativeVideoHostView()
    view.backgroundColor = .black
    if onSwipeAdjustment != nil {
      context.coordinator.installSwipeGesture(in: view)
    }
    if onHorizontalSeek != nil {
      context.coordinator.installHorizontalSeekGesture(in: view)
    }
    updateUIView(view, context: context)
    return view
  }

  func updateUIView(_ view: LiveNativeVideoHostView, context: Context) {
    view.host(playback.player.videoLayer, gravity: controller.imageMode.videoGravity)
    context.coordinator.swipeGestureHandler = onSwipeAdjustment
    context.coordinator.horizontalSeekHandler = onHorizontalSeek
  }

  static func dismantleUIView(_ view: LiveNativeVideoHostView, coordinator: LivePlayerLayerCoordinator) {
    coordinator.invalidate()
  }
}

// A layer has one superlayer: whichever surface is on screen (player page or mini player) takes it.
final class LiveNativeVideoHostView: UIView {
  private var videoLayer: AVSampleBufferDisplayLayer?

  func host(_ layer: AVSampleBufferDisplayLayer, gravity: AVLayerVideoGravity) {
    videoLayer = layer
    layer.videoGravity = gravity
    claimLayer()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    claimLayer()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    if videoLayer?.superlayer === layer {
      videoLayer?.frame = bounds
    }
    CATransaction.commit()
  }

  private func claimLayer() {
    guard window != nil, let videoLayer, videoLayer.superlayer !== layer else { return }
    videoLayer.removeFromSuperlayer()
    layer.addSublayer(videoLayer)
    setNeedsLayout()
  }
}
