import SwiftUI

struct LivePlayerView: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let dependencies: AppDependencies
  @EnvironmentObject var preferences: LiveAppPreferencesStore
  let posterURL: URL?
  @Binding var cinemaMode: Bool
  @State var showsOptions = false
  @State var showsChapters = false

  @State var seekFeedback: PlayerDoubleTapSeekFeedback?
  @State var doubleTapSeek: (target: TimeInterval, seconds: Int, direction: PlayerDoubleTapSeekDirection, at: Date)?
  @State var swipeAdjustment: PlayerSwipeAdjustmentState?
  @State var volumeButtonLevel: PlayerSwipeAdjustmentState?
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
  @GestureState var isSpeedRamping = false
  @State var horizontalSeekPreview: (position: TimeInterval, isFine: Bool)?
  @StateObject var systemVolume = LiveSystemVolume()
  @State var autoPictureInPictureArmed = true
  @State var autoPictureInPictureActive = false
  @StateObject var nativeControls = LiveNativeControlsState()
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled
  var isScrolled = false

  var accessibleControls: Bool {
    preferences.preferences.usesAccessiblePlayerControls(voiceOver: voiceOverEnabled)
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        LiveSystemVolumeView(volume: systemVolume)
          .frame(width: 1, height: 1)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
        Color.black

        videoSurface(width: proxy.size.width)
          .onChange(of: accessibleControls, initial: true) { _, value in
            nativeControls.staysVisible = value
          }

        if controller.audioOnly {
          LiveAudioOnlyPoster(
            posterURL: posterURL,
            title: controller.stream?.title ?? controller.video.title,
            isPlaying: controller.state == .playing,
            showsDetails: showsAudioOnlyDetails
          )
        }

        speedBoostOverlay
        swipeAdjustmentOverlay
        statusOverlay
        if controller.drawsOwnControls {
          LiveNativeSubtitleOverlay(controller: controller, subtitles: controller.nativeSubtitles)
          LiveNativePlayerControls(
            controller: controller,
            controls: nativeControls,
            isFullscreen: showsFullscreenLayout,
            onFullscreen: {
              AppLogger.playback.info(
                "fullscreen: toggle pressed flag=\(controller.isPresentingFullscreen, privacy: .public) layout=\(showsFullscreenLayout, privacy: .public)"
              )
              // The layout follows the window, not the flag: a landscape window without the flag must still exit.
              if controller.isPresentingFullscreen || showsFullscreenLayout {
                controller.exitNativeFullscreen("player-toggle", byUser: true)
              } else {
                controller.enterNativeFullscreen("player-toggle")
              }
            },
            onOptions: { showsOptions = true },
            onChapters: { showsChapters = true }
          )
          .opacity(horizontalSeekPreview == nil ? 1 : 0)
          .allowsHitTesting(horizontalSeekPreview == nil)
        }
        seekFeedbackOverlay
        horizontalSeekOverlay
        // Above the transport controls: below them the UIKit overlay never gets taps.
        LiveSponsorBlockOverlay(
          controller: controller,
          fillsAvailableSpace: false
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 10)
        playbackStatusAccessibilityElement
        playbackPositionAccessibilityElement

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

    .sheet(isPresented: $showsChapters) {
      LivePlayerChaptersView(controller: controller) { showsChapters = false }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
    coordinator.presentation == .expanded && controller.drawsOwnPlayer
  }
}
