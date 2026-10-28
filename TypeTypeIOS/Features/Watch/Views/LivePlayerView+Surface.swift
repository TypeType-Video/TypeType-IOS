import SwiftUI

extension LivePlayerView {
  func videoSurface(
    width: CGFloat,
    surface: LiveNativeVideoView.Surface = .page
  ) -> some View {
    surfaceContent(surface: surface)
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
      .simultaneousGesture(
        DragGesture(minimumDistance: 10)
          .onChanged { value in
            // The ramp rides the same touch as the long-press boost; the
            // UIKit pans are cancelled while the hold owns the touch.
            guard longPressBaseRate != nil else { return }
            applySpeedRamp(translationHeight: value.translation.height)
          }
      )
  }

  @ViewBuilder
  private func surfaceContent(
    surface: LiveNativeVideoView.Surface
  ) -> some View {
    if let playback = controller.nativePlayback {
      LiveNativeVideoView(
        playback: playback,
        controller: controller,
        surface: surface,
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
