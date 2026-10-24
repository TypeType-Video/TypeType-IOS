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
  }
}
