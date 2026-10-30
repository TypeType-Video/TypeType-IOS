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
      .simultaneousGesture(
        DragGesture(minimumDistance: 30)
          .onEnded { value in
            guard showsFullscreenLayout || controller.isPresentingFullscreen,
              value.translation.height > 120,
              abs(value.translation.width) < value.translation.height,
              abs(value.startLocation.x - width / 2) < width / 6
            else { return }
            controller.exitNativeFullscreen("surface-drag")
          }
      )
  }

  private var speedRampGesture: some Gesture {
    LongPressGesture(minimumDuration: 0.35)
      .sequenced(before: DragGesture(minimumDistance: 0))
      .onChanged { value in
        switch value {
        case .first(true):
          beginSpeedRamp()
        case let .second(true, drag?):
          beginSpeedRamp()
          applySpeedRamp(translationHeight: drag.translation.height)
        default:
          break
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
