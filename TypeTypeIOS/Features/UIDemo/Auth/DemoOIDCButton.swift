import SwiftUI

struct DemoOIDCButton: View {
  let palette: DemoAuthPalette
  let action: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Rectangle().frame(height: 1)
        Text("or")
          .font(.caption)
          .foregroundStyle(palette.secondaryText)
        Rectangle().frame(height: 1)
      }
      .foregroundStyle(palette.border)

      Button(action: action) {
        Label("Continue with OpenID", systemImage: "person.badge.key.fill")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(palette.primaryText)
          .frame(maxWidth: .infinity)
          .frame(minHeight: 46)
          .background(palette.fieldSurface)
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .strokeBorder(palette.border)
          }
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("demo.auth.oidc")
    }
  }
}
