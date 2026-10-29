import AVFoundation
import SwiftUI

struct LiveNativeVideoView: UIViewRepresentable {
  enum Surface: Int {
    // Priority by raw value: the docked card outranks the scrolled-out
    // page, the landscape stage outranks both.
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
    // The layer must never paint outside the host, otherwise interim frames
    // bleed a band below the controls row during the transition.
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
    // While the landscape full screen owns the layer, the page must not
    // re-bind it: a controller installed on a layer that then jumps
    // windows is what the system auto-promotes to Picture in Picture.
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

// A layer has one superlayer: the visible surface that matters most (fullscreen, then the player
// page, then the mini player) shows it; the latest one wins a tie.
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
    // No flush: it would starve the picture until the next segment while audio plays on. Both hosts
    // share the 16:9 container, so the carried frame is right.
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
    // Adopting across surfaces keeps the previous frame; sizing here means
    // no stale fullscreen-sized band can render before the layout pass.
    layer.frame = bounds
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    guard let videoLayer, videoLayer.superlayer === layer else { return }
    // No action-disabling transaction: the layer frame animates with the
    // SwiftUI container, otherwise the picture moves out of step with the
    // letterboxing and a stale band shows under the controls.
    videoLayer.frame = bounds
  }
}
