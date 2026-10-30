import SwiftUI

extension Text {
  func liveSectionHeader() -> some View {
    self
      .font(.subheadline.weight(.semibold))
      .textCase(nil)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 4)
      .padding(.bottom, 6)
  }
}
