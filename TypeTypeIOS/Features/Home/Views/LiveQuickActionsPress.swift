import SwiftUI
import UIKit

// Gestures on the view, not a Button: a long press added to a Button inside a ScrollView never fires.
struct LiveQuickActionsPress: ViewModifier {
  @Binding var showsActions: Bool
  let action: () -> Void
  @State private var pending = false

  func body(content: Content) -> some View {
    content
      .contentShape(Rectangle())
      .onTapGesture(perform: action)
      .onLongPressGesture(minimumDuration: 0.45) {
        pending = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } onPressingChanged: { pressing in
        guard !pressing, pending else { return }
        pending = false
        showsActions = true
      }
      .accessibilityAddTraits(.isButton)
      .accessibilityAction(.default, action)
      .accessibilityAction(named: Text("More actions")) { showsActions = true }
  }
}

extension View {
  func liveQuickActionsPress(showsActions: Binding<Bool>, action: @escaping () -> Void) -> some View {
    modifier(LiveQuickActionsPress(showsActions: showsActions, action: action))
  }
}
