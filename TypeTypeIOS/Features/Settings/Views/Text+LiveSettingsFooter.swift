import SwiftUI

extension Text {
  func liveSettingsHeader() -> some View {
    self
      .font(.subheadline.weight(.semibold))
      .textCase(nil)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 4)
      .padding(.bottom, 6)
  }

  func liveSettingsFooter() -> some View {
    self
      .font(.footnote)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
