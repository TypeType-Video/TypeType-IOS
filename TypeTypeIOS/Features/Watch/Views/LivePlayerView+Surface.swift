import SwiftUI

extension LivePlayerView {
  func videoSurface(width: CGFloat) -> some View {
    surfaceContent
      .accessibilityIdentifier("live.player.surface")
      .overlay {
        LivePictureInPictureNotice(pictureInPicture: controller.pictureInPicture)
      }
      .onGeometryChange(for: CGRect.self) { proxy in
        proxy.frame(in: .global)
      } action: { frame in
        evaluateAutoPictureInPicture(frame)
      }
      .onAppear {
        // A surface that reappears after a PiP round trip must not come
        // back with hidden controls.
        controller.pictureInPicture.markControlsRefresh()
      }
      // Seek and speed gestures live on the video surface only: as
      // container-level simultaneous gestures they also fired when
      // tapping controls, so double-tapping pause sought -10s.
      .simultaneousGesture(
        SpatialTapGesture(count: 2)
          .onEnded { value in
            nativeControls.cancelTap()
            handleDoubleTap(at: value.location, width: width)
          }
      )
      .simultaneousGesture(
        TapGesture()
          .onEnded {
            if controller.nativePlayback != nil { nativeControls.tap() }
          }
      )
      .onLongPressGesture(
        minimumDuration: 0.35,
        perform: {},
        onPressingChanged: { pressing in
          setLongPressBoost(active: pressing)
        }
      )
  }

  @ViewBuilder
  private var surfaceContent: some View {
    if let playback = controller.nativePlayback {
      LiveNativeVideoView(
        playback: playback,
        controller: controller,
        onSwipeAdjustment: { handleSwipeAdjustment($0) },
        onHorizontalSeek: { handleHorizontalSeek($0) }
      )
    } else {
      LivePlayerLayerView(
        player: controller.player,
        controller: controller,
        onSwipeAdjustment: { handleSwipeAdjustment($0) },
        onHorizontalSeek: { handleHorizontalSeek($0) },
        onPictureInPictureUIRestore: { completion in
          PictureInPictureRestore.restore(
            canRestore: coordinator.hasActivePlayback,
            prepare: { coordinator.expand() },
            isPrepared: { coordinator.presentation == .expanded },
            completion: completion
          )
        }
      )
    }
  }
}
