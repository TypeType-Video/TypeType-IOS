import SwiftUI

struct LiveLibrarySectionContext: Equatable {
  let value: LiveLibrarySection
  let binding: Binding<LiveLibrarySection>

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.value == rhs.value
  }
}

struct LiveLibrarySectionContextKey: EnvironmentKey {
  static let defaultValue: LiveLibrarySectionContext? = nil
}

struct LiveLibrarySectionSwipe: ViewModifier {
  @Environment(\.librarySectionContext) private var section
  @Environment(\.dismiss) private var dismiss
  @State private var homeSection: LiveLibrarySection?

  func body(content: Content) -> some View {
    content
      .onAppear {
        homeSection = section?.value
      }
      .onChange(of: section?.value) { _, newValue in
        guard let homeSection, let newValue, newValue != homeSection else {
          return
        }
        dismiss()
      }
      .simultaneousGesture(
        DragGesture(minimumDistance: 28)
          .onEnded { value in
            guard abs(value.translation.width)
              > abs(value.translation.height) * 1.25,
              let homeSection,
              let index = LiveLibrarySection.allCases.firstIndex(of: homeSection)
            else { return }
            let target = index + (value.translation.width < 0 ? 1 : -1)
            guard LiveLibrarySection.allCases.indices.contains(target) else {
              return
            }
            section?.binding.wrappedValue = LiveLibrarySection.allCases[target]
          }
      )
  }
}

extension EnvironmentValues {
  var librarySectionContext: LiveLibrarySectionContext? {
    get { self[LiveLibrarySectionContextKey.self] }
    set { self[LiveLibrarySectionContextKey.self] = newValue }
  }
}

extension View {
  func liveLibrarySectionSwipe() -> some View {
    modifier(LiveLibrarySectionSwipe())
  }
}
