import SwiftUI

/// The history page's resume bar, reused on every thumbnail that knows the
/// watch progress. Apply before `clipShape` so the bar follows the corners.
extension View {
  @ViewBuilder
  func liveThumbnailProgress(_ fraction: Double?) -> some View {
    if let fraction, fraction > 0 {
      overlay(alignment: .bottom) {
        ProgressView(value: min(fraction, 1))
          .tint(DemoTheme.accent)
          .background(.black.opacity(0.4))
      }
    } else {
      self
    }
  }
}
