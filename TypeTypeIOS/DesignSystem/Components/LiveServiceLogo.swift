import SwiftUI
import UIKit

extension VideoService {
  // NicoNico's official mark is black: left as a template it takes the text colour, so it stays visible in dark mode.
  var logo: Image {
    if let branded = Self.brandedLogos[id] {
      return branded
    }
    return assetName.map { Image($0).renderingMode(.template) } ?? Image(systemName: systemImage)
  }

  private static let brandedLogos: [Int: Image] = {
    var logos: [Int: Image] = [:]
    logos[0] = colored("ServiceYouTube", UIColor(red: 1, green: 0, blue: 0, alpha: 1), whiteBehind: CGRect(x: 8, y: 7, width: 9, height: 10))
    logos[5] = colored("ServiceBiliBili", UIColor(red: 0, green: 0.631, blue: 0.839, alpha: 1))
    return logos.compactMapValues { $0 }
  }()

  // The YouTube play triangle is a hole in the path: white behind it gives the official white triangle.
  private static func colored(_ assetName: String, _ color: UIColor, whiteBehind: CGRect? = nil) -> Image? {
    guard let mask = UIImage(named: assetName) else { return nil }
    let scale = CGAffineTransform(scaleX: mask.size.width / 24, y: mask.size.height / 24)
    let image = UIGraphicsImageRenderer(size: mask.size).image { _ in
      if let whiteBehind {
        UIColor.white.setFill()
        UIRectFill(whiteBehind.applying(scale))
      }
      mask.withTintColor(color, renderingMode: .alwaysOriginal).draw(in: CGRect(origin: .zero, size: mask.size))
    }
    return Image(uiImage: image.withRenderingMode(.alwaysOriginal))
  }
}

struct LiveServiceLogo: View {
  let service: VideoService
  var size: CGFloat = 22

  var body: some View {
    service.logo
      .resizable()
      .scaledToFit()
      .foregroundStyle(.primary)
      .frame(width: size, height: size)
      .accessibilityHidden(true)
  }
}
