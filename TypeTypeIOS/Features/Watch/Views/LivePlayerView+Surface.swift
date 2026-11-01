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
      // With AVKit's own controls they stay off, or a tap on AVKit's buttons is taken from them.
      .simultaneousGesture(
        SpatialTapGesture(count: 2)
          .onEnded { value in
            nativeControls.cancelTap()
            handleDoubleTap(at: value.location, width: width)
          },
        including: ownTapGestures
      )
      .simultaneousGesture(
        TapGesture()
          .onEnded { nativeControls.tap() },
        including: ownTapGestures
      )
      .simultaneousGesture(speedRampGesture, including: ownTapGestures)
      .onChange(of: isSpeedRamping) { _, ramping in
        if !ramping { endSpeedRamp() }
      }
  }

  // One gesture owns the speed ramp: a separate long press and drag let the drag win before the hold.
  // `.first(true)` arrives on touch down, before the hold: starting there left every plain tap stuck at 2x, since a
  // failed long press never reaches onEnded. The GestureState resets on end, failure and cancel alike.
  private var speedRampGesture: some Gesture {
    LongPressGesture(minimumDuration: PlayerFullscreenExitRules.speedRampHold)
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

  private var ownTapGestures: GestureMask {
    controller.drawsOwnControls ? .all : .subviews
  }

  private var fullscreenExitAction: (() -> Void)? {
    guard showsFullscreenLayout || controller.isPresentingFullscreen else { return nil }
    // Down from full screen hands the video to PiP and the mini player; the button is the way back to the page.
    return { coordinator.minimize() }
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
        onHorizontalSeek: { handleHorizontalSeek($0) },
        onFullscreenExit: fullscreenExitAction
      )
    } else {
      LivePlayerLayerView(
        player: controller.player,
        controller: controller,
        onSwipeAdjustment: { handleSwipeAdjustment($0) },
        onHorizontalSeek: { handleHorizontalSeek($0) },
        onFullscreenExit: fullscreenExitAction,
        onPictureInPictureUIRestore: { completion in
          PictureInPictureRestore.restore(
            canRestore: coordinator.hasActivePlayback,
            prepare: { coordinator.expand() },
            isPrepared: { coordinator.presentation == .expanded },
            completion: completion
          )
        },
        showsSystemControls: !controller.drawsOwnControls
      )
    }
  }
}
