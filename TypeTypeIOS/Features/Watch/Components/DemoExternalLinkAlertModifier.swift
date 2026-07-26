import SwiftUI

struct DemoExternalLinkAlertModifier: ViewModifier {
  @Environment(\.openURL) private var openURL
  @Binding var pendingURL: URL?

  func body(content: Content) -> some View {
    content.alert(
      "Attention: You’re leaving TypeType",
      isPresented: Binding(
        get: { pendingURL != nil },
        set: { if !$0 { pendingURL = nil } }
      )
    ) {
      Button("Continue in browser") {
        if let pendingURL {
          openURL(pendingURL)
        }
        pendingURL = nil
      }
      Button("Stay in TypeType", role: .cancel) {
        pendingURL = nil
      }
    } message: {
      Text(
        "This link opens \(pendingURL?.host ?? "an external website") outside the app."
      )
    }
  }
}

extension View {
  func demoExternalLinkAlert(pendingURL: Binding<URL?>) -> some View {
    modifier(DemoExternalLinkAlertModifier(pendingURL: pendingURL))
  }
}
