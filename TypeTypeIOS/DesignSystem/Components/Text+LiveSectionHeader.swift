import SwiftUI

extension Text {
  /// Section header without the system's opaque background block: with
  /// custom card rows the default header chrome (square, overlapping the
  /// rounded cards below) clashed with the page design.
  func liveSectionHeader() -> some View {
    self
      .font(.headline)
      .textCase(nil)
      .foregroundStyle(.primary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 26)
      .padding(.bottom, 10)
      // The system paints its own block around the header slot; this
      // background bleeds past the slot's insets so nothing shows around
      // the title — the header sits directly on the page colour.
      .background(
        DemoTheme.pageBackground
          .padding(.horizontal, -24)
          .padding(.vertical, -12)
      )
  }
}
