import SwiftUI

struct DemoAuthView: View {
  @Environment(\.themePalette) private var palette
  @State private var mode: DemoAuthMode
  @State private var name = ""
  @State private var email = ""
  @State private var password = ""
  @State private var isLight = false
  let onAuthenticated: () -> Void

  init(initialMode: DemoAuthMode, onAuthenticated: @escaping () -> Void) {
    _mode = State(initialValue: initialMode)
    self.onAuthenticated = onAuthenticated
  }

  var body: some View {
    ZStack {
      DemoAuthBackdrop(isLight: isLight)

      GeometryReader { proxy in
        ScrollView(.vertical) {
          VStack {
            Spacer(minLength: 92)

            DemoAuthCard(
              mode: $mode,
              name: $name,
              email: $email,
              password: $password,
              isLight: isLight,
              onAuthenticated: onAuthenticated
            )
            .padding(.horizontal, horizontalPadding(for: proxy.size.width))

            Spacer(minLength: 48)
          }
          .frame(minHeight: proxy.size.height)
          .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
      }
    }
    .overlay(alignment: .topTrailing) {
      themeButton
        .padding(.top, 14)
        .padding(.trailing, 16)
    }
    .tint(isLight ? palette.accent : .white)
    .preferredColorScheme(isLight ? .light : .dark)
  }

  private var themeButton: some View {
    Button {
      withAnimation(.easeInOut(duration: 0.25)) {
        isLight.toggle()
      }
    } label: {
      Image(systemName: isLight ? "moon.fill" : "sun.max.fill")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(
          isLight ? Color.black.opacity(0.78) : Color.white
        )
        .frame(width: 42, height: 42)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .overlay {
          Circle()
            .strokeBorder(
              isLight
                ? Color.black.opacity(0.14)
                : Color.white.opacity(0.14),
              lineWidth: 1
            )
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      isLight ? "Use dark appearance" : "Use light appearance"
    )
  }

  private func horizontalPadding(for width: CGFloat) -> CGFloat {
    width < 500 ? 32 : 44
  }
}
