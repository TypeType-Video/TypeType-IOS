import SwiftUI

/// Runs `action` once a press on the view looks like a tap: the finger rests
/// for a moment or lifts without moving. A scroll never triggers it, so a
/// swipe through the feed does not open sessions at the provider.
private struct LivePrewarmOnPress: ViewModifier {
  /// Long enough to tell a resting finger from the start of a scroll.
  static let restDelay: Duration = .milliseconds(90)
  static let scrollSlop: CGFloat = 10

  let action: () -> Void
  @State private var didRun = false
  @State private var restTask: Task<Void, Never>?

  func body(content: Content) -> some View {
    content.simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { value in
          guard !Self.isScroll(value) else {
            restTask?.cancel()
            return
          }
          guard !didRun, restTask == nil else { return }
          restTask = Task { @MainActor in
            try? await Task.sleep(for: Self.restDelay)
            guard !Task.isCancelled else { return }
            run()
          }
        }
        .onEnded { value in
          restTask?.cancel()
          restTask = nil
          if !Self.isScroll(value) { run() }
        }
    )
  }

  private func run() {
    guard !didRun else { return }
    didRun = true
    action()
  }

  private static func isScroll(_ value: DragGesture.Value) -> Bool {
    hypot(value.translation.width, value.translation.height) > scrollSlop
  }
}

extension View {
  func livePrewarmOnPress(_ action: @escaping () -> Void) -> some View {
    modifier(LivePrewarmOnPress(action: action))
  }
}
