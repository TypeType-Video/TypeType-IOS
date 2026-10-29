import SwiftUI

struct DemoProfileAvatarView: View {
  @Environment(\.themePalette) private var palette
  @EnvironmentObject private var session: DemoSessionStore
  let size: CGFloat

  var body: some View {
    Group {
      if let data = session.profileAvatarData {
        DemoAnimatedImageView(data: data)
      } else if let emoji = session.profileEmoji {
        Text(emoji)
          .font(.system(size: size * 0.55))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(palette.surface)
      } else {
        Image("TypeTypeLogo")
          .resizable()
          .scaledToFit()
          .padding(size * 0.12)
          .background(palette.surface)
      }
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: size * 0.24))
    .accessibilityLabel("Profile avatar")
  }
}
