import SwiftUI

struct DemoSectionLabel: View {
  let title: String

  var body: some View {
    Text(title.uppercased())
      .font(.caption.weight(.semibold))
      .tracking(1.25)
      .foregroundStyle(.secondary)
      .accessibilityLabel(title)
  }
}
