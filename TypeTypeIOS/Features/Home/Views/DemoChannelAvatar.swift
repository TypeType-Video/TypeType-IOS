import SwiftUI

struct DemoChannelAvatar: View {
  let name: String
  let artwork: DemoArtwork
  var size: CGFloat = 30

  var body: some View {
    ZStack {
      Circle()
        .fill(background)
      Image(artwork.rawValue)
        .resizable()
        .interpolation(.none)
        .scaledToFit()
        .padding(size * 0.16)
    }
    .frame(width: size, height: size)
    .accessibilityLabel(name)
  }

  private var background: Color {
    switch artwork {
    case .television:
      return .indigo
    case .dog:
      return .orange
    case .cat:
      return .purple
    case .bird:
      return .cyan
    case .pipePipe:
      return Color(red: 0.03, green: 0.48, blue: 0.68)
    case .typeType:
      return Color(red: 0.94, green: 0.27, blue: 0.29)
    }
  }
}
