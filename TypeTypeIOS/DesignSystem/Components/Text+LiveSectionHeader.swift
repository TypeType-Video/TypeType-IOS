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
    modifier(SlotChromeCover())
  }
}

private struct SlotChromeCover: ViewModifier {
  @Environment(\.liveInGroupedList) private var grouped

  func body(content: Content) -> some View {
    // The system header chrome exists on GROUPED lists too — the cover is
    // needed everywhere, painted in the list's own background colour (the
    // gap colour between cards in grouped lists).
    ZStack(alignment: .leading) {
      slotColor
        .padding(.horizontal, -24)
        .padding(.vertical, -12)
      content.frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(
      slotColor
        .padding(.horizontal, -24)
        .padding(.vertical, -12)
    )
  }

  private var slotColor: Color {
    grouped ? DemoTheme.groupedBackground : DemoTheme.rowBackground
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
