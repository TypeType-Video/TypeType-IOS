import SwiftUI

extension Text {
  /// Section header in the TypeType design language (mirrors the Android
  /// `PlainSectionHeader`): small uppercase caption, medium weight, wide
  /// letter spacing, muted colour, no chrome behind it.
  func liveSectionHeader() -> some View {
    self
      .font(.caption.weight(.medium))
      .textCase(.uppercase)
      .kerning(1.5)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 4)
      .padding(.bottom, 8)
      .liveSectionSlotChrome()
  }
}

extension View {
  /// iOS 27 list chrome: section header/footer slots get a system
  /// background that neither `UITableViewHeaderFooterView.appearance()`
  /// nor `backgroundView` removes (SwiftUI renders it). A background that
  /// bleeds past the slot insets (measured: -24 horizontal, -12 vertical)
  /// covers the chrome with the page colour.
  func liveSectionSlotChrome() -> some View {
    background(
      DemoTheme.background
        .padding(.horizontal, -24)
        .padding(.vertical, -12)
    )
  }
}
