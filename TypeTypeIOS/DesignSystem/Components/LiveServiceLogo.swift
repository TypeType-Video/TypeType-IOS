import SwiftUI
import UIKit

extension VideoService {
  // Menus tint template images with the app accent: the logo is pre-tinted with the label colour instead, which UIKit
  // resolves to black in light mode and white in dark mode.
  var logo: Image {
    guard let assetName, let mask = UIImage(named: assetName) else { return Image(systemName: systemImage) }
    return Image(uiImage: mask.withTintColor(.label, renderingMode: .alwaysOriginal))
  }
}

struct LiveServiceLogo: View {
  let service: VideoService
  var size: CGFloat = 22

  var body: some View {
    Group {
      if let assetName = service.assetName {
        Image(assetName).renderingMode(.template).resizable()
      } else {
        Image(systemName: service.systemImage).resizable()
      }
    }
    .scaledToFit()
    .foregroundStyle(.primary)
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}
