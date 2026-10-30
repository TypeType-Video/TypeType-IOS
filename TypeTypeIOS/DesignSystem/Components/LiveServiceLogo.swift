import SwiftUI

extension VideoService {
  var logo: Image {
    assetName.map { Image($0) } ?? Image(systemName: systemImage)
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
