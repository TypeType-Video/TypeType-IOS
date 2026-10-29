import SwiftUI

/// The vertical "⋮" menu glyph, drawn from shapes: SF Symbols in menu
/// labels get tinted by the accent colour, and their weight cannot be
/// controlled.
struct LiveDotsGlyph: View {
  var body: some View {
    VStack(spacing: 2.5) {
      ForEach(0..<3, id: \.self) { _ in
        Circle()
          .fill(Color.primary)
          .frame(width: 4, height: 4)
      }
    }
    .frame(width: 24, height: 24)
    .contentShape(Rectangle())
  }
}

/// Rows in the title colour (the default style tints them all with the accent); destructive stays red.
struct LiveDotMenuRowStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(
        configuration.role == .destructive ? Color.red : Color.primary
      )
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .contentShape(Rectangle())
  }
}

/// The "…" menu: a plain button plus a popover. A SwiftUI `Menu` leaves its
/// label behind at the presentation position when it closes mid-scroll:
/// the button froze at a fixed screen spot instead of following the card.
struct LiveDotMenu<Content: View>: View {
  @State private var isPresented = false
  @State private var anchorFrame: CGRect?
  @State private var opensUpward = true
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    Button {
      // The side is picked at open time from the button's screen position:
      // in the upper half the bubble opens downward, otherwise upward, so
      // it always fits between the screen edges.
      if let frame = anchorFrame {
        opensUpward = frame.midY > UIScreen.main.bounds.height / 2
      }
      isPresented = true
    } label: {
      LiveDotsGlyph()
    }
    .onGeometryChange(for: CGRect.self) { proxy in
      proxy.frame(in: .global)
    } action: { frame in
      anchorFrame = frame
    }
    .popover(
      isPresented: $isPresented,
      attachmentAnchor: .point(.init(x: 0.5, y: 0.0)),
      arrowEdge: opensUpward ? .bottom : .top
    ) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          content
        }
      }
      .buttonStyle(LiveDotMenuRowStyle())
      .padding(8)
      .frame(width: 300, alignment: .leading)
      // Never taller than the screen can show: excess rows scroll.
      .frame(maxHeight: 460)
      // Any tap inside fires the row's action AND closes the popup,
      // matching menu behaviour.
      .simultaneousGesture(TapGesture().onEnded { isPresented = false })
      .presentationCompactAdaptation(.popover)
    }
  }
}

/// Hands the quick-actions menu to video cards, which show it behind their "…" button.
struct LiveQuickActionsMenuKey: EnvironmentKey {
  static let defaultValue: AnyView? = nil
}
