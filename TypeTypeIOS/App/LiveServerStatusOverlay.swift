import SwiftUI

struct LiveServerStatusOverlay: ViewModifier {
  let monitor: LiveServerStatusMonitor?
  let active: Bool

  func body(content: Content) -> some View {
    if let monitor {
      content
        .overlay(alignment: .top) { LiveServerStatusBanner(monitor: monitor).padding(.top, 4) }
        .animation(.easeOut(duration: 0.25), value: monitor.message)
        .onChange(of: monitor.message) { _, message in
          if let message { AccessibilityNotification.Announcement(message).post() }
        }
        .task(id: active) {
          guard active else { return }
          await monitor.run()
        }
    } else {
      content
    }
  }
}
