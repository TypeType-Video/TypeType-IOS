import SwiftUI
import UIKit

extension VideoService {
  var logo: Image {
    Self.brandedLogos[id] ?? Image(systemName: systemImage)
  }

  private static let brandedLogos: [Int: Image] = {
    var logos: [Int: Image] = [:]
    logos[0] = colored("ServiceYouTube", UIColor(red: 1, green: 0, blue: 0, alpha: 1), whiteBehind: CGRect(x: 8, y: 7, width: 9, height: 10))
    logos[5] = colored("ServiceBiliBili", UIColor(red: 0, green: 0.631, blue: 0.839, alpha: 1))
    // NicoNico's mark is black: the label colour keeps it black in light mode and white in dark mode. A template
    // image would take the menu tint (the accent) instead.
    logos[6] = colored("ServiceNicoNico", .label)
    return logos.compactMapValues { $0 }
  }()

  private static func colored(_ assetName: String, _ color: UIColor, whiteBehind: CGRect? = nil) -> Image? {
    guard let mask = UIImage(named: assetName) else { return nil }
    let tinted = mask.withTintColor(color, renderingMode: .alwaysOriginal)
    guard let whiteBehind else { return Image(uiImage: tinted) }
    // The YouTube play triangle is a hole in the path: white behind it gives the official white triangle.
    let scale = CGAffineTransform(scaleX: mask.size.width / 24, y: mask.size.height / 24)
    let image = UIGraphicsImageRenderer(size: mask.size).image { _ in
      UIColor.white.setFill()
      UIRectFill(whiteBehind.applying(scale))
      tinted.draw(in: CGRect(origin: .zero, size: mask.size))
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
      .frame(width: size, height: size)
      .accessibilityHidden(true)
  }
}
