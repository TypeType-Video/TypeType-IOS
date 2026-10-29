import SwiftUI

struct DemoMoreSectionCard<Content: View>: View {
  @Environment(\.themePalette) private var palette
  let title: String
  @ViewBuilder let content: Content

  init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      DemoSectionLabel(title: title)
      VStack(spacing: 0) {
        content
      }
      .padding(.horizontal, 14)
      .background(palette.groupedSurface)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
  }
}
