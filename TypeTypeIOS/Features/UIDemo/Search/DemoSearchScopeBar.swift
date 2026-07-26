import SwiftUI

struct DemoSearchScopeBar: View {
  @Binding var selection: DemoSearchScope

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(DemoSearchScope.allCases) { scope in
          Button {
            withAnimation(.snappy(duration: 0.22)) {
              selection = scope
            }
          } label: {
            Label(scope.rawValue, systemImage: scope.systemImage)
              .font(.footnote.weight(.semibold))
              .padding(.horizontal, 13)
              .frame(height: 36)
              .foregroundStyle(selection == scope ? .white : .primary)
              .background(
                selection == scope
                  ? Color.accentColor
                  : DemoTheme.surface
              )
              .clipShape(Capsule())
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("demo.search.scope.\(scope.rawValue.lowercased())")
        }
      }
      .padding(.horizontal, 16)
    }
    .scrollIndicators(.hidden)
  }
}
