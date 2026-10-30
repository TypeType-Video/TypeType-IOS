import SwiftUI

struct LiveLibraryActionGlass: ViewModifier {
  @Environment(\.themePalette) private var palette
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.glassEffect()
    } else {
      content.background(
        palette.groupedSurface,
        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
    }
  }
}

struct LiveLibrarySectionStrip: View {
  @Binding var selection: LiveLibrarySection
  @Environment(\.themePalette) private var palette
  @State private var stripPosition: LiveLibrarySection?

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(LiveLibrarySection.allCases) { section in
          Button {
            withAnimation(.easeInOut(duration: 0.28)) {
              selection = section
            }
          } label: {
            Text(section.title)
              .font(.body.weight(.semibold))
              .foregroundStyle(
                section == selection ? Color.primary : Color.secondary
              )
              .padding(.horizontal, 18)
              .frame(height: 40)
              .background(
                section == selection
                  ? palette.surface
                  : Color.clear,
                in: Capsule()
              )
          }
          .buttonStyle(.plain)
          .id(section)
          .accessibilityAddTraits(
            section == selection ? [.isSelected] : []
          )
        }
      }
      .padding(.horizontal, 16)
      .scrollTargetLayout()
    }
    .scrollPosition(id: $stripPosition, anchor: .center)
    .scrollTargetBehavior(.viewAligned)
    .onChange(of: selection) { _, newValue in
      guard stripPosition != newValue else { return }
      withAnimation(.easeInOut(duration: 0.28)) {
        stripPosition = newValue
      }
    }
    .onAppear { stripPosition = selection }
    .padding(.vertical, 4)
    .background(palette.background)
  }
}
