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
  /// covers the chrome with the page colour. The full-width frame is load
  /// bearing: a short footer text left the right part of the chrome block
  /// uncovered.
  func liveSectionSlotChrome() -> some View {
    // Two layers on purpose: the background bleed covers the chrome on
    // grouped lists, and the ZStack colour sits in the CONTENT layer, above
    // the slot chrome that iOS 26/27 draws over plain-list headers.
    ZStack(alignment: .leading) {
      SlotChromeBackground()
      self
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(SlotChromeBackground())
  }
}

/// The page colour for slot chrome. Reads the ENVIRONMENT palette (not a
/// static) so it repaints the moment the theme switches — a static left the
/// caption bands in the old theme until the page was recreated.
private struct SlotChromeBackground: View {
  var body: some View {
    // The PAGE colour (pageBackground), not the background role: background
    // is the card white here, which painted white bands above every card.
    DemoTheme.pageBackground
      .padding(.horizontal, -24)
      .padding(.vertical, -12)
  }
}
