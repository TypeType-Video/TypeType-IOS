import SwiftUI
import UIKit

/// Environment-driven page background: repaints live on theme changes.
struct DemoThemeBackground: View {
  @Environment(\.themePalette) private var palette

  var body: some View {
    palette.background
  }
}

/// Pill button in the Apple-TV-style action language: fully rounded
/// capsules. The primary action is the white pill with dark label; all
/// other actions are translucent dark pills with white labels. Toggled-on
/// states tint surface and label with the accent. Height is uniform so
/// every cell in the action grid matches.
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
        if #available(iOS 26.0, *) {
          // Liquid Glass pill, tinted with the theme colour.
          Capsule(style: .continuous)
            .fill(background.opacity(0.28))
            .glassEffect(.regular.tint(background), in: .capsule)
        } else {
          Capsule(style: .continuous)
            .fill(background)
        }
      }
      .overlay(
        Capsule(style: .continuous)
          .strokeBorder(
            isFilled
              ? Color.clear
              : (isActive
                ? palette.accent.opacity(0.35)
                : Color.primary.opacity(0.14)),
            lineWidth: 1
          )
      )
      .contentShape(Rectangle())
      .opacity(configuration.isPressed ? 0.6 : 1)
  }

  private var foreground: Color {
    if isFilled {
      return palette.background
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

/// Shared row-surface rule for feed-style lists that intentionally remain flat.
/// Settings/admin/profile surfaces use `liveGroupedList()` instead; this
/// modifier is retained for media/feed lists where a continuous list is the
/// correct presentation.
extension View {
  func liveThemedList() -> some View {
    modifier(LiveThemedListModifier())
  }
}

private struct LiveThemedListModifier: ViewModifier {
  @Environment(\.themePalette) private var palette

  func body(content: Content) -> some View {
    content
      // `.plain`, NOT `.insetGrouped`: the grouped style draws white
      // rounded section cards behind the rows on iOS 26/27 (the "rounded
      // pills"), and row backgrounds cannot cover them — only the list
      // style removes them. Android's settings screens have no cards
      // either: flat rows and hairline dividers on the page colour.
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      // The list background IS the row colour: it shows through
      // transparent rows (NavigationLinks etc.) and in the gaps between
      // filled rows, so every page renders rows the same way. Under AMOLED
      // this is the theme surface on the black page.
      .background(palette.rowBackground)
      .environment(\.defaultMinListRowHeight, 44)
      .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
      // This is intentionally a flat/feed-style list. Settings and other
      // preference surfaces use liveGroupedList() for the modern grouped
      // appearance; media queues and content feeds stay continuous.
      .listRowBackground(palette.rowBackground)
      .listRowSeparatorTint(palette.separator)
      // The navigation bar takes the SAME variable as the page — otherwise
      // it stays system-white above a coloured page (the "colour is
      // different at the very top" symptom).
      .toolbarBackground(palette.background, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
  }
}

/// `ContentUnavailableView` and other empty states paint their own system
/// background (the black/grey boxes in themed pages). This fills the whole
/// screen with the page colour instead.
extension View {
  func liveThemedEmptyState() -> some View {
    self
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(DemoThemeBackground())
  }

  /// iOS 26 paints its own fill under rows whose content is a control (Toggle, Button), on top
  /// of `listRowBackground`. The row colour bleeds past the content insets to cover it.
  func liveRowFill() -> some View {
    frame(maxWidth: .infinity, minHeight: 44)
      .background(ThemeRowFill().padding(.horizontal, -20))
      .liveRowBackground()
  }
}

/// Android-style selection menu: a filled surface popup with the options
/// and a checkmark on the current one (the Android theme popup look). The
/// system menu popups are Liquid Glass and cannot take the theme surface,
/// so selection rows open this popover instead.
struct LiveOptionMenu<Option: Hashable>: View {
  let title: String
  @Binding var selection: Option
  let options: [(value: Option, label: String)]
  @State private var isPresented = false
  @Environment(\.themePalette) private var palette

  init(
    _ title: String,
    selection: Binding<Option>,
    options: [(Option, String)]
  ) {
    self.title = title
    self._selection = selection
    self.options = options.map { (value: $0.0, label: $0.1) }
  }

  var body: some View {
    Button {
      isPresented = true
    } label: {
      HStack(spacing: 12) {
        Text(title)
          .foregroundStyle(palette.textPrimary)
        Spacer(minLength: 12)
        Text(currentLabel)
          .foregroundStyle(palette.textSecondary)
          .lineLimit(1)
          // Anchored on the VALUE text so the menu drops where the selected
          // value sits (like the system pickers), not at the row centre.
          .popover(
            isPresented: $isPresented,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .top
          ) {
            VStack(alignment: .leading, spacing: 0) {
              ForEach(options.indices, id: \.self) { index in
                Button {
                  selection = options[index].value
                  isPresented = false
                } label: {
                  HStack(spacing: 12) {
                    Text(options[index].label)
                      .foregroundStyle(palette.textPrimary)
                    Spacer(minLength: 12)
                    if options[index].value == selection {
                      Image(systemName: "checkmark")
                        .foregroundStyle(palette.accent)
                    }
                  }
                  .padding(.horizontal, 16)
                  .frame(minHeight: 44)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if index < options.count - 1 {
                  Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                }
              }
            }
            .frame(width: 280)
            .presentationCompactAdaptation(.popover)
            .presentationBackground(palette.surface)
            .presentationCornerRadius(20)
          }
      }
      .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
    }
    .buttonStyle(.plain)
    .liveRowFill()
  }

  private var currentLabel: String {
    options.first(where: { $0.value == selection })?.label ?? ""
  }
}

/// SwiftUI ships no `Color.systemRed`; the Settings tiles use the iOS
/// Settings palette, so bridge UIKit's adaptive system colours across.
/// They follow light/dark automatically like every other system colour.
extension Color {
  static let systemBlue = Color(uiColor: .systemBlue)
  static let systemRed = Color(uiColor: .systemRed)
  static let systemPurple = Color(uiColor: .systemPurple)
  static let systemOrange = Color(uiColor: .systemOrange)
  static let systemGreen = Color(uiColor: .systemGreen)
  static let systemTeal = Color(uiColor: .systemTeal)
  static let systemGray = Color(uiColor: .systemGray)
}

/// Compact confirmation card presented as a dropping-down popover — the
/// user wants confirms to open like the dropdowns (downward), never as a
/// sheet sliding up from the bottom.
struct LiveConfirmCard: View {
  let title: String
  var message: String? = nil
  let confirmTitle: String
  var destructive = true
  let onConfirm: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 8) {
        Text(title)
          .font(.headline)
          .multilineTextAlignment(.center)
        if let message, !message.isEmpty {
          Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider()

      Button(role: destructive ? ButtonRole.destructive : nil) {
        dismiss()
        onConfirm()
      } label: {
        Text(confirmTitle)
          .fontWeight(.semibold)
          .foregroundStyle(
            destructive ? AnyShapeStyle(Color.systemRed) : AnyShapeStyle(.tint)
          )
          .frame(maxWidth: .infinity, minHeight: 50)
      }
      .buttonStyle(.plain)

      Divider()

      Button("Cancel") { dismiss() }
        .fontWeight(.semibold)
        .foregroundStyle(.tint)
        .frame(maxWidth: .infinity, minHeight: 50)
        .buttonStyle(.plain)
    }
    .frame(width: 280)
    .presentationCompactAdaptation(.popover)
  }
}

extension View {
  /// The app's standard confirm: a glass card dropping from the attached
  /// element (see LiveConfirmCard). Replaces every confirmationDialog.
  func liveConfirmPopover(
    isPresented: Binding<Bool>,
    title: String,
    message: String? = nil,
    confirmTitle: String,
    destructive: Bool = true,
    onConfirm: @escaping () -> Void
  ) -> some View {
    popover(
      isPresented: isPresented,
      attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
      arrowEdge: .top
    ) {
      LiveConfirmCard(
        title: title,
        message: message,
        confirmTitle: confirmTitle,
        destructive: destructive,
        onConfirm: onConfirm
      )
    }
  }
}

extension View {
  /// Rounded section cards on the page colour. Sections paint their own rows with
  /// `liveRowBackground()`, so the system's grouped background can go.
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
  /// Themed Liquid Glass card: glass tinted with the theme's row colour on iOS 26, the plain
  /// row colour below.
  func liveGlassCard(cornerRadius: CGFloat = 14) -> some View {
    background(LiveGlassFill(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), opacity: 0.55))
  }

  /// Themed Liquid Glass pill for compact chips (stats, actions).
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
