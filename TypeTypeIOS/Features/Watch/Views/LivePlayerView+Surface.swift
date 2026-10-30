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
        controller.pictureInPicture.markControlsRefresh()
      }
      // Seek and speed gestures on the video surface only: at container level a double tap on pause also seeks.
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
            if controller.nativePlayback != nil || controller.isOfflineContent {
              nativeControls.tap()
            }
          }
      )
      .simultaneousGesture(speedRampGesture)
      .onChange(of: isSpeedRamping) { _, ramping in
        if !ramping { endSpeedRamp() }
      }
      .simultaneousGesture(
        DragGesture(minimumDistance: 30)
          .onEnded { value in
            guard showsFullscreenLayout || controller.isPresentingFullscreen,
              value.translation.height > 120,
              abs(value.translation.width) < value.translation.height,
              abs(value.startLocation.x - width / 2) < width / 6
            else { return }
            controller.exitNativeFullscreen("surface-drag", byUser: true)
          }
      )
  }

  // One gesture owns the speed ramp: a separate long press and drag let the drag win before the hold.
  // `.first(true)` arrives on touch down, before the hold: starting there left every plain tap stuck at 2x, since a
  // failed long press never reaches onEnded. The GestureState resets on end, failure and cancel alike.
  private var speedRampGesture: some Gesture {
    LongPressGesture(minimumDuration: 0.35)
      .sequenced(before: DragGesture(minimumDistance: 0))
      .updating($isSpeedRamping) { value, ramping, _ in
        if case .second(true, _) = value { ramping = true }
      }
      .onChanged { value in
        guard case let .second(true, drag) = value else { return }
        beginSpeedRamp()
        if let drag {
          applySpeedRamp(translationHeight: drag.translation.height)
        }
      }
      .onEnded { _ in
        endSpeedRamp()
      }
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
        },
        showsSystemControls: !controller.isOfflineContent
      )
    }
  }
}
