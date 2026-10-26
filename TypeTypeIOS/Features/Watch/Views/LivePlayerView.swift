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
  @StateObject var nativeControls = LiveNativeControlsState()


  var body: some View {
    GeometryReader { proxy in
      ZStack {
        Color.black

        videoSurface(width: proxy.size.width)

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
        if controller.nativePlayback != nil {
          LiveNativeSubtitleOverlay(controller: controller)
          LiveNativePlayerControls(controller: controller, controls: nativeControls) {
            LiveLandscapeHostingController.present(for: controller)
          }
        }
        // Above the transport controls: the UIKit overlay below never received taps.
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

