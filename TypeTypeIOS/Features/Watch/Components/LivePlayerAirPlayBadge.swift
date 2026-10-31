import SwiftUI

// Stays while the controls are hidden, so an active AirPlay route can always be changed or stopped.
struct LivePlayerAirPlayBadge: View {
  @StateObject private var route = LiveAirPlayRoute()
  let sendsSoundOnly: Bool

  var body: some View {
    if let name = route.deviceName {
      HStack(spacing: 6) {
        AirPlayRouteButton()
          .frame(width: 26, height: 26)
        Text(sendsSoundOnly ? String(localized: "Sound on \(name)") : name)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.white)
          .lineLimit(1)
      }
      .padding(.leading, 4)
      .padding(.trailing, 10)
      .padding(.vertical, 3)
      .background(.ultraThinMaterial, in: Capsule())
      .environment(\.colorScheme, .dark)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(10)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(sendsSoundOnly ? String(localized: "Sound on \(name)") : name)
      .accessibilityHint("Changes or stops AirPlay")
    }
  }
}
