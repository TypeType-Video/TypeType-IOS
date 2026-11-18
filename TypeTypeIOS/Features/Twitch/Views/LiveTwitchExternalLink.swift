import SwiftUI

struct LiveTwitchExternalLinkConfirmation: ViewModifier {
  @Binding var url: URL?
  let onOpen: (URL) -> Void

  func body(content: Content) -> some View {
    content.alert(
      "Open an external link?",
      isPresented: Binding(get: { url != nil }, set: { if !$0 { url = nil } }),
      presenting: url
    ) { target in
      Button("Open link") { onOpen(target) }
      Button("Cancel", role: .cancel) {}
    } message: { target in
      Text("This link leaves TypeType. The site may be unsafe, and it will see your IP address.\n\(target.absoluteString)")
    }
  }
}

extension View {
  func liveTwitchExternalLinkConfirmation(_ url: Binding<URL?>, onOpen: @escaping (URL) -> Void) -> some View {
    modifier(LiveTwitchExternalLinkConfirmation(url: url, onOpen: onOpen))
  }
}
