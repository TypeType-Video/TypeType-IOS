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
      // Paints over whatever chrome iOS draws behind the header slot: the
      // page colour in the header's own bounds, so the system's square
      // block cannot show through.
      .background(DemoTheme.pageBackground)
  }
}
