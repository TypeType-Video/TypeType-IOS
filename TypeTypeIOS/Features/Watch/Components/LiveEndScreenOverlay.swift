import SwiftUI

struct LiveEndScreenOverlay: View {
  @ObservedObject var controller: LivePlayerController
  let onOpen: (URL) -> Void

  var body: some View {
    GeometryReader { proxy in
      let shown = visibleElements
      if !shown.isEmpty {
        let frame = LiveEndScreenElement.videoFrame(in: proxy.size, videoAspectRatio: videoAspectRatio)
        ForEach(shown) { element in
          let box = element.box(in: frame)
          LiveEndScreenCard(element: element) {
            if let url = URL(string: element.url) { onOpen(url) }
          }
          .frame(width: box.width, height: box.height)
          .position(x: box.midX, y: box.midY)
        }
      }
    }
  }

  private var visibleElements: [LiveEndScreenElement] {
    guard controller.settings.hideEndScreens != true, !controller.audioOnly,
      let elements = controller.stream?.endScreenElements
    else { return [] }
    let time = controller.position
    return elements.filter { $0.isUsable && $0.isVisible(at: time) }
  }

  private var videoAspectRatio: CGFloat {
    guard let video = controller.preparation?.video, video.width > 0, video.height > 0 else { return 16 / 9 }
    return CGFloat(video.width) / CGFloat(video.height)
  }
}

private struct LiveEndScreenCard: View {
  let element: LiveEndScreenElement
  let action: () -> Void

  private var isRound: Bool { element.kind == .channel || element.kind == .website }

  var body: some View {
    Button(action: action) {
      GeometryReader { proxy in
        ZStack(alignment: .bottomLeading) {
          Color.black.opacity(0.4)
          LiveRemoteImage(url: LiveImageURLResolver.resolve(element.thumbnailURL))
          if !isRound, proxy.size.width >= 96, !element.title.isEmpty {
            Text(verbatim: element.title)
              .font(.caption2.weight(.semibold))
              .foregroundStyle(.white)
              .lineLimit(2)
              .padding(.horizontal, 6)
              .padding(.top, 12)
              .padding(.bottom, 4)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom))
          }
        }
      }
      .clipShape(shape)
      .overlay(shape.stroke(.white.opacity(0.25), lineWidth: 1))
      .contentShape(shape)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(verbatim: element.title))
    .accessibilityHint(hint)
  }

  private var shape: AnyShape {
    isRound ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private var hint: Text {
    switch element.kind {
    case .video: Text("Plays this video.")
    case .playlist: Text("Opens this playlist.")
    case .channel: Text("Opens this channel.")
    case .website, nil: Text("Opens this website after asking.")
    }
  }
}
