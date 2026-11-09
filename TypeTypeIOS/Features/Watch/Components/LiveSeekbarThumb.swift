import SwiftUI
import UIKit

struct LiveSeekbarThumb: View {
  let icon: LiveSeekbarIcon
  let isScrubbing: Bool

  static func size(for icon: LiveSeekbarIcon, isScrubbing: Bool) -> CGFloat {
    switch icon {
    case .plain: isScrubbing ? 20 : 13
    case .typeType, .custom: isScrubbing ? 34 : 26
    }
  }

  var body: some View {
    let size = Self.size(for: icon, isScrubbing: isScrubbing)
    Group {
      switch icon {
      case .plain:
        Circle().fill(.white).shadow(color: .black.opacity(0.3), radius: 2, y: 1)
      case .typeType:
        TypeTypeSeekbarGlyph()
      case let .custom(url):
        LiveSeekbarRemoteIcon(url: url)
      }
    }
    .frame(width: size, height: size)
    .animation(.easeOut(duration: 0.12), value: isScrubbing)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

struct TypeTypeSeekbarGlyph: View {
  private static let red = Color(red: 0xEF / 255, green: 0x44 / 255, blue: 0x44 / 255)

  var body: some View {
    Canvas { context, size in
      let scale = min(size.width, size.height) / 64
      context.translateBy(x: (size.width - 64 * scale) / 2, y: (size.height - 64 * scale) / 2)
      context.scaleBy(x: scale, y: scale)
      var antenna = Path()
      antenna.move(to: CGPoint(x: 21, y: 6))
      antenna.addLine(to: CGPoint(x: 32, y: 17))
      antenna.addLine(to: CGPoint(x: 43, y: 6))
      context.stroke(antenna, with: .color(Self.red), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
      context.fill(Path(roundedRect: CGRect(x: 5, y: 17, width: 54, height: 41), cornerRadius: 9), with: .color(Self.red))
      context.fill(Path(roundedRect: CGRect(x: 11, y: 23, width: 30, height: 29), cornerRadius: 4), with: .color(.white))
      context.fill(Path(ellipseIn: CGRect(x: 46.5, y: 27.5, width: 7, height: 7)), with: .color(.white))
      context.fill(Path(ellipseIn: CGRect(x: 46.5, y: 39.5, width: 7, height: 7)), with: .color(.white))
    }
  }
}

struct LiveSeekbarRemoteIcon: View {
  let url: URL
  @State private var loaded: (url: URL, image: UIImage?)?

  var body: some View {
    Group {
      if let loaded, loaded.url == url, let image = loaded.image {
        LiveAnimatedImage(image: image)
      } else {
        TypeTypeSeekbarGlyph().opacity(loaded?.url == url ? 1 : 0)
      }
    }
    .task(id: url) {
      let image = await LiveSeekbarIconLoader.shared.image(for: url)
      guard !Task.isCancelled else { return }
      loaded = (url, image)
    }
  }
}

struct LiveAnimatedImage: UIViewRepresentable {
  let image: UIImage

  func makeUIView(context: Context) -> UIImageView {
    let view = UIImageView()
    view.contentMode = .scaleAspectFit
    view.setContentHuggingPriority(.defaultLow, for: .horizontal)
    view.setContentHuggingPriority(.defaultLow, for: .vertical)
    view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    return view
  }

  func updateUIView(_ view: UIImageView, context: Context) {
    if view.image !== image { view.image = image }
  }
}
