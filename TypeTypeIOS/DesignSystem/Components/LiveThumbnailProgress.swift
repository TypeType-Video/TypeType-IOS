import SwiftUI

extension View {
  @ViewBuilder
  func liveThumbnailProgress(_ fraction: Double?) -> some View {
    if let fraction, fraction > 0 {
      overlay(alignment: .bottom) {
        ProgressView(value: min(fraction, 1))
          .background(.black.opacity(0.4))
      }
    } else {
      self
    }
  }
}
