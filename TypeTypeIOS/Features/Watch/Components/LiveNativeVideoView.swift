import AVFoundation
import SwiftUI

struct LiveNativeVideoView: UIViewRepresentable {
  enum Surface: Int {
    case page = 1
    case mini = 2
    case fullscreen = 3
  }

  let playback: LiveNativePlayback
  let controller: LivePlayerController
  var surface = Surface.page
  var onSwipeAdjustment: ((PlayerSwipeAdjustmentEvent) -> Void)? = nil
  var onHorizontalSeek: ((PlayerHorizontalSeekEvent) -> Void)? = nil

  func makeCoordinator() -> LivePlayerLayerCoordinator {
    LivePlayerLayerCoordinator(controller: controller)
  }

  func makeUIView(context: Context) -> LiveNativeVideoHostView {
    let view = LiveNativeVideoHostView()
    view.surface = surface
    view.backgroundColor = .black
    // Never paint outside the host: interim frames bleed a band under the controls during the transition.
    view.clipsToBounds = true
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
    playback.player.videoLayer.videoGravity = controller.imageMode.videoGravity
    if view.window != nil && view.bounds.size.width > 0 {
      view.setNeedsLayout()
    }
    view.surface = surface
    if view.owner !== playback.layerOwner {
      view.owner = playback.layerOwner
      if view.window != nil { playback.layerOwner.attach(view) }
    }
    // Do not re-bind while landscape full screen owns the layer: a controller on a layer that changes windows gets
    // promoted to PiP.
    if surface == .page, !controller.isPresentingFullscreen {
      controller.pictureInPicture.installNativeContent(
        layer: playback.player.videoLayer,
        playback: playback.pictureInPictureSource
      )
    }
    context.coordinator.swipeGestureHandler = onSwipeAdjustment
    context.coordinator.horizontalSeekHandler = onHorizontalSeek
  }

  static func dismantleUIView(_ view: LiveNativeVideoHostView, coordinator: LivePlayerLayerCoordinator) {
    coordinator.invalidate()
  }
}

@MainActor
final class LiveNativeLayerOwner {
  private let layer: AVSampleBufferDisplayLayer
  private var hosts: [WeakHost] = []

  private struct WeakHost {
    weak var view: LiveNativeVideoHostView?
  }

  init(layer: AVSampleBufferDisplayLayer) {
    self.layer = layer
  }

  func attach(_ host: LiveNativeVideoHostView) {
    hosts.removeAll { $0.view == nil || $0.view === host }
    hosts.append(WeakHost(view: host))
    place()
  }

  func detach(_ host: LiveNativeVideoHostView) {
    hosts.removeAll { $0.view == nil || $0.view === host }
    place()
  }

  private func place() {
    let visible = hosts.compactMap(\.view).filter { $0.window != nil }
    guard let host = visible.max(by: { $0.surface.rawValue <= $1.surface.rawValue }) else { return }
    // No flush: it starves the picture until the next segment while audio plays on.
    host.adopt(layer)
  }
}

final class LiveNativeVideoHostView: UIView {
  weak var owner: LiveNativeLayerOwner?
  var surface = LiveNativeVideoView.Surface.page
  private weak var videoLayer: AVSampleBufferDisplayLayer?

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window != nil {
      owner?.attach(self)
    } else {
      owner?.detach(self)
    }
  }

  func adopt(_ layer: AVSampleBufferDisplayLayer) {
    videoLayer = layer
    guard layer.superlayer !== self.layer else { return }
    layer.removeFromSuperlayer()
    self.layer.addSublayer(layer)
    layer.frame = bounds
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    guard let videoLayer, videoLayer.superlayer === layer else { return }
    // No action-disabling transaction: the layer must animate with its container or a stale band shows under the
    // controls.
    videoLayer.frame = bounds
  }
}
