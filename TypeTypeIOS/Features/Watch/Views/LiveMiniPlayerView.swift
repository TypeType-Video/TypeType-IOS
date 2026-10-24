import AVFoundation
import SwiftUI

struct LiveMiniPlayerView: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let onExpand: () -> Void
  @State private var dragTranslation: CGFloat = 0
  @ScaledMetric(relativeTo: .body) private var playbackControlWidth = 34
  @ScaledMetric(relativeTo: .body) private var playbackControlHeight = 40
  @ScaledMetric(relativeTo: .body) private var closeControlWidth = 30
  @ScaledMetric(relativeTo: .body) private var closeControlHeight = 40

  var body: some View {
    if let video = coordinator.currentVideo,
      let controller = coordinator.controller {
      VStack(spacing: 0) {
        ProgressView(
          value: min(max(controller.position, 0), max(controller.duration, 1)),
          total: max(controller.duration, 1)
        )
        .progressViewStyle(.linear)
        .tint(DemoTheme.accent)
        .frame(height: 2)

        HStack(spacing: 11) {
          Button(action: onExpand) {
            ZStack {
              LiveRemoteImage(url: video.thumbnail)
                .frame(width: 80, height: 45)
                .aspectRatio(16 / 9, contentMode: .fill)
                .clipped()
                .clipShape(
                  RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
              if controller.state == .playing, !controller.audioOnly {
                LiveVideoPreviewLayer(player: controller.player)
                  .frame(width: 80, height: 45)
                  .clipShape(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                  )
                  .allowsHitTesting(false)
              }
            }
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Open \(video.title)")
          .accessibilityIdentifier("live.miniplayer.open")

          Button(action: onExpand) {
            VStack(alignment: .leading, spacing: 3) {
              Text(video.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
              Text(video.uploaderName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .buttonStyle(.plain)

          if coordinator.sleepTimer.isActive {
            Image(systemName: "moon.zzz.fill")
              .font(.caption)
              .foregroundStyle(.tint)
              .accessibilityLabel(
                "Sleep timer \(coordinator.sleepTimer.summary)"
              )
          }

          Button(action: controller.togglePlayback) {
            Image(
              systemName: controller.state == .playing
                ? "pause.fill"
                : "play.fill"
            )
            .frame(
              width: playbackControlWidth,
              height: playbackControlHeight
            )
          }
          .accessibilityLabel(
            controller.state == .playing ? "Pause" : "Play"
          )
          .accessibilityIdentifier("live.miniplayer.playback")

          Button(action: coordinator.close) {
            Image(systemName: "xmark")
              .frame(width: closeControlWidth, height: closeControlHeight)
          }
          .accessibilityLabel("Close player")
          .accessibilityIdentifier("live.miniplayer.close")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
      }
      .frame(maxWidth: .infinity)
      .background(.regularMaterial)
      .overlay(alignment: .top) {
        Divider()
      }
      .offset(y: dragTranslation)
      .opacity(dragOpacity)
      .gesture(miniPlayerDragGesture)
      .accessibilityElement(children: .contain)
      .accessibilityAction(named: "Expand player") {
        onExpand()
      }
      .accessibilityAction(named: "Close player") {
        coordinator.close()
      }
      .accessibilityIdentifier("live.miniplayer")
    }
  }

  private var dragOpacity: Double {
    let distance = abs(dragTranslation)
    guard distance > MiniPlayerDragGesture.activationDistance else {
      return 1
    }
    return max(
      0.35,
      1 - (distance - MiniPlayerDragGesture.activationDistance) / 180
    )
  }

  private var miniPlayerDragGesture: some Gesture {
    DragGesture(minimumDistance: 12)
      .onChanged { value in
        let vertical = value.translation.height
        dragTranslation = abs(vertical) > abs(value.translation.width)
          ? vertical
          : 0
      }
      .onEnded { value in
        defer {
          withAnimation(.snappy(duration: 0.18)) {
            dragTranslation = 0
          }
        }

        switch MiniPlayerDragGesture.action(
          forTranslationHeight: value.translation.height
        ) {
        case .expand:
          onExpand()
        case .close:
          coordinator.close()
        case nil:
          break
        }
      }
  }
}

/// Renders the playing video in the mini player: the same AVPlayer can back
/// several layers, so the small preview shows live video while the full
/// surface is off screen. Audio-only keeps the poster instead.
private struct LiveVideoPreviewLayer: UIViewRepresentable {
  let player: AVPlayer

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .clear
    let layer = AVPlayerLayer(player: player)
    layer.videoGravity = .resizeAspect
    layer.frame = view.bounds
    layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
    view.layer.addSublayer(layer)
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {}
}
