import SwiftUI

extension Text {
  /// Section header in the TypeType design language (Android `PlainSectionHeader`): small
  /// uppercase caption, medium weight, wide letter spacing, muted colour.
  func liveSectionHeader() -> some View {
    self
      .font(.caption.weight(.medium))
      .textCase(.uppercase)
      .kerning(1.5)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 4)
      .padding(.bottom, 8)
  }
}
