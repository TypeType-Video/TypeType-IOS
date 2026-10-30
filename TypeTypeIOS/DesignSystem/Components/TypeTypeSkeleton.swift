import SwiftUI

struct TypeTypeSkeleton: View {
  @Environment(\.themePalette) private var palette
  var cornerRadius: CGFloat = 0
  @State private var dimmed = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      .fill(palette.groupedSurface)
      .opacity(dimmed ? 0.38 : 0.72)
      .animation(reduceMotion ? nil : .easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: dimmed)
      .onAppear { dimmed = true }
      .accessibilityHidden(true)
  }
}
