import SwiftUI
import UIKit

struct LiveThemeBackground: View {
  @Environment(\.themePalette) private var palette

  var body: some View {
    palette.background
  }
}

struct LiveChipButtonStyle: ButtonStyle {
  var isFilled = false
  var isActive = false
  @Environment(\.themePalette) private var palette

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.footnote.weight(isFilled ? .semibold : .medium))
      .foregroundStyle(foreground)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .frame(minHeight: 38)
      .background {
        if #available(iOS 26.0, *), !isFilled {
          Capsule(style: .continuous)
            .fill(background.opacity(0.28))
            .glassEffect(.regular.tint(background), in: .capsule)
        } else {
          Capsule(style: .continuous)
            .fill(background)
        }
      }
      .overlay(Capsule(style: .continuous).strokeBorder(stroke, lineWidth: 1))
      .contentShape(Rectangle())
      .opacity(configuration.isPressed ? 0.6 : 1)
  }

  private var stroke: Color {
    if isFilled {
      return .clear
    }
    return isActive ? palette.accent.opacity(0.35) : Color.primary.opacity(0.14)
  }

  private var foreground: Color {
    if isFilled {
      return isActive ? .white : palette.background
    }
    return isActive ? palette.accent : .primary
  }

  private var background: Color {
    if isFilled {
      return isActive ? palette.accent : Color.primary.opacity(0.92)
    }
    return isActive ? palette.accent.opacity(0.16) : palette.elevatedSurface
  }
}

extension View {
  func liveThemedList() -> some View {
    modifier(LiveThemedListModifier())
  }
}

private struct LiveThemedListModifier: ViewModifier {
  @Environment(\.themePalette) private var palette

  func body(content: Content) -> some View {
    content
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(palette.rowBackground)
      .environment(\.defaultMinListRowHeight, 44)
      .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
      .listRowBackground(palette.rowBackground)
      .listRowSeparatorTint(palette.separator)
      // Otherwise the bar stays system white above a coloured page.
      .toolbarBackground(palette.background, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
  }
}

// ContentUnavailableView paints a system background: fill it with the page colour.
extension View {
  func liveThemedEmptyState() -> some View {
    self
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(LiveThemeBackground())
  }

  // iOS 26 paints its own fill under control rows, above listRowBackground: the row colour bleeds past the insets to
  // cover it.
  func liveRowFill() -> some View {
    frame(maxWidth: .infinity, minHeight: 44)
      .background(ThemeRowFill().padding(.horizontal, -20))
      .liveRowBackground()
  }
}

extension Color {
  static let systemBlue = Color(uiColor: .systemBlue)
  static let systemRed = Color(uiColor: .systemRed)
  static let systemPurple = Color(uiColor: .systemPurple)
  static let systemIndigo = Color(uiColor: .systemIndigo)
  static let systemPink = Color(uiColor: .systemPink)
  static let systemOrange = Color(uiColor: .systemOrange)
  static let systemGreen = Color(uiColor: .systemGreen)
  static let systemTeal = Color(uiColor: .systemTeal)
  static let systemGray = Color(uiColor: .systemGray)
}

extension View {
  func liveGroupedList() -> some View {
    modifier(LiveGroupedListModifier())
  }

}

private struct LiveGroupedListModifier: ViewModifier {
  @Environment(\.themePalette) private var palette

  func body(content: Content) -> some View {
    content
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(palette.background)
  }
}

extension View {
  func liveGlassCard(cornerRadius: CGFloat = 14) -> some View {
    background(LiveGlassFill(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), opacity: 0.55))
  }

  func liveGlassChip() -> some View {
    padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(LiveGlassFill(shape: Capsule(style: .continuous), opacity: 0.5))
  }
}

private struct LiveGlassFill<S: Shape>: View {
  let shape: S
  let opacity: Double
  @Environment(\.themePalette) private var palette

  var body: some View {
    if #available(iOS 26.0, *) {
      shape
        .fill(palette.rowBackground.opacity(opacity))
        .glassEffect(.regular.tint(palette.rowBackground), in: shape)
    } else {
      shape.fill(palette.rowBackground)
    }
  }
}
