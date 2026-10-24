import SwiftUI

extension Text {
  /// Section header without the system's opaque background block: with
  /// custom card rows the default header chrome (square, overlapping the
  /// rounded cards below) clashed with the page design.
  func liveSectionHeader() -> some View {
    self
      .font(.footnote.weight(.semibold))
      .textCase(nil)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.top, 18)
      .padding(.bottom, 8)
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
