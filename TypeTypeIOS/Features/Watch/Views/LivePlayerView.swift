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
  @State var speedBoostRate: Float?
  nonisolated(unsafe) static var gestureLog: [String] = []

  static func logGesture(_ text: String) {
    #if DEBUG
    gestureLog.insert(text, at: 0)
    if gestureLog.count > 4 { gestureLog.removeLast() }
    AppLogger.playback.info("gesture: \(text, privacy: .public)")
    #endif
  }
  @State var systemBrightnessBeforeSwipe: CGFloat?
  @State var longPressBaseRate: Float?
  @State var longPressBoostTask: Task<Void, Never>?
  @State var horizontalSeekPreview: TimeInterval?
  @State var autoPictureInPictureArmed = true
  @State var autoPictureInPictureActive = false
  @StateObject var nativeControls = LiveNativeControlsState()
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  /// Drives the rounded lower corners: the "content slides under the
  /// pinned player" hint while the watch page is scrolled.
  var isScrolled = false


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
        speedBoostOverlay
        swipeAdjustmentOverlay
        statusOverlay
        if controller.nativePlayback != nil {
          LiveNativeSubtitleOverlay(controller: controller)
          LiveNativePlayerControls(
            controller: controller,
            controls: nativeControls,
            isFullscreen: showsFullscreenLayout
          ) {
            AppLogger.playback.info("fullscreen: toggle pressed flag=\(controller.isPresentingFullscreen, privacy: .public)")
            if controller.isPresentingFullscreen {
              controller.exitNativeFullscreen("player-toggle")
            } else {
              controller.enterNativeFullscreen("player-toggle")
            }
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
    .modifier(
      LivePlayerSizing(
        isFullscreen: showsFullscreenLayout,
        cinemaMode: cinemaMode,
        isScrolled: isScrolled
      )
    )
    .overlay(alignment: .top) {
      if !showsFullscreenLayout,
        let remaining = coordinator.autoplayCountdownRemaining {
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
    .onAppear {
      controller.fullscreen.isPageActive = followsDeviceRotation
    }
    .onChange(of: followsDeviceRotation) { _, follows in
      controller.fullscreen.isPageActive = follows
    }
    .onDisappear {
      restoreSystemBrightness()
      controller.fullscreen.isPageActive = false
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

  var showsFullscreenLayout: Bool {
    controller.showsFullscreenLayout(verticalSizeClass: verticalSizeClass)
  }

  private var followsDeviceRotation: Bool {
    coordinator.presentation == .expanded && controller.nativePlayback != nil
  }
}

/// Inline the player is a 16:9 card; full screen it fills the window and
/// rides the system rotation animation instead of fading over it. The
/// layout priority wins the page's VStack so the pinned metadata below
/// collapses to nothing while fullscreen.
struct LivePlayerSizing: ViewModifier {
  let isFullscreen: Bool
  let cinemaMode: Bool
  var isScrolled = false

  @ViewBuilder
  func body(content: Content) -> some View {
    if isFullscreen {
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        // Outermost: a priority buried inside another modifier never
        // reaches the parent VStack, and the metadata then splits the
        // height with the player instead of collapsing.
        .layoutPriority(1)
    } else {
      content
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(
          UnevenRoundedRectangle(
            topLeadingRadius: cinemaMode ? 0 : 16,
            bottomLeadingRadius: lowerRadius,
            bottomTrailingRadius: lowerRadius,
            topTrailingRadius: cinemaMode ? 0 : 16,
            style: .continuous
          )
        )
    }
  }

  /// Lower corners round only while the page is scrolled — the "content
  /// slides under the pinned player" hint. In cinema mode the player
  /// bleeds 16 pt past each screen edge, so the radius covers that
  /// distance to land the visible curve on the screen edge.
  private var lowerRadius: CGFloat {
    guard isScrolled else { return cinemaMode ? 0 : 16 }
    return cinemaMode ? 40 : 24
  }
}
