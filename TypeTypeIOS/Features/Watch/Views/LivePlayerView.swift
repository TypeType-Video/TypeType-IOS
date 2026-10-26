import SwiftUI

struct LivePlayerView: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let dependencies: AppDependencies
  @ObservedObject var preferences = LiveAppPreferencesStore.shared
  let posterURL: URL?
  @Binding var cinemaMode: Bool
  @State var showsOptions = false

  @State var seekFeedback: PlayerDoubleTapSeekFeedback?
  @State var doubleTapSeek: (target: TimeInterval, seconds: Int, direction: PlayerDoubleTapSeekDirection, at: Date)?
  @State var doubleTapSeekTask: Task<Void, Never>?
  @State var swipeAdjustment: PlayerSwipeAdjustmentState?
  @State var systemBrightnessBeforeSwipe: CGFloat?
  @State var longPressBaseRate: Float?
  @State var longPressBoostTask: Task<Void, Never>?
  @State var horizontalSeekPreview: TimeInterval?
  @State var autoPictureInPictureArmed = true
  @State var autoPictureInPictureActive = false


  var body: some View {
    GeometryReader { proxy in
      ZStack {
        Color.black

        LivePlayerLayerView(
          player: controller.player,
          controller: controller,
          onSwipeAdjustment: { event in
            handleSwipeAdjustment(event)
          },
          onHorizontalSeek: { event in
            handleHorizontalSeek(event)
          },
          onPictureInPictureUIRestore: { completion in
            PictureInPictureRestore.restore(
              canRestore: coordinator.hasActivePlayback,
              prepare: {
                coordinator.expand()
              },
              isPrepared: {
                coordinator.presentation == .expanded
              },
              completion: completion
            )
          }
        )
          .accessibilityIdentifier("live.player.surface")
          .overlay {
            LivePictureInPictureNotice(
              pictureInPicture: controller.pictureInPicture
            )
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
                handleDoubleTap(
                  at: value.location,
                  width: proxy.size.width
                )
              }
          )
          .onLongPressGesture(
            minimumDuration: 0.35,
            perform: {},
            onPressingChanged: { pressing in
              setLongPressBoost(active: pressing)
            }
          )

        if controller.audioOnly {
          ZStack {
            LiveRemoteImage(url: posterURL)
              .scaledToFill()
              .blur(radius: 28)
              .opacity(0.48)
              .clipped()
            Image(systemName: "waveform")
              .font(.system(size: 44, weight: .medium))
              .foregroundStyle(.white)
          }
          .allowsHitTesting(false)
        }

        seekFeedbackOverlay
        horizontalSeekOverlay
        swipeAdjustmentOverlay
        statusOverlay
        // Above the transport controls on purpose: the UIKit player overlay
        // sits under the SwiftUI controls and never received taps on Skip.
        LiveSponsorBlockOverlay(
          controller: controller,
          fillsAvailableSpace: false
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 10)
        playbackStatusAccessibilityElement
        playbackPositionAccessibilityElement

        Button {
          showsOptions = true
        } label: {
          overlayIcon("slider.horizontal.3")
        }
        .buttonStyle(.plain)
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity,
          alignment: .topTrailing
        )
        .padding(10)
        .accessibilityLabel("Player options")
        .accessibilityIdentifier("live.player.options")
      }
    }
    .aspectRatio(16 / 9, contentMode: .fit)
    .clipShape(
      RoundedRectangle(
        cornerRadius: cinemaMode ? 0 : 16,
        style: .continuous
      )
    )
    .overlay(alignment: .top) {
      if let remaining = coordinator.autoplayCountdownRemaining {
        HStack(spacing: 10) {
          Text("Next video in \(remaining)s")
            .font(.footnote.weight(.semibold))
            .monospacedDigit()
          Button("Play now") {
            coordinator.skipAutoplayCountdown()
          }
          .font(.footnote.weight(.semibold))
          Button("Cancel", role: .destructive) {
            coordinator.cancelAutoplayCountdown()
          }
          .font(.footnote)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.82), in: Capsule())
        .padding(.top, 10)
        .accessibilityIdentifier("live.player.autoplay-countdown")
      }
    }
    .onDisappear {
      restoreSystemBrightness()
    }

    .sheet(isPresented: $showsOptions) {
      LivePlayerOptionsSheet(
        controller: controller,
        coordinator: coordinator,
        dependencies: dependencies,
        cinemaMode: $cinemaMode
      )
    }
  }
}

