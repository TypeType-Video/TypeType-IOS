import SwiftUI

extension Text {
  func liveSettingsFooter() -> some View {
    self
      .font(.footnote)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
