import SwiftUI

extension LivePlayerView {
  var swipeAdjustmentOverlay: some View {
    ZStack {
      if let adjustment = swipeAdjustment ?? volumeButtonLevel {
        LivePlayerLevelOverlay(kind: adjustment.kind, fraction: adjustment.fraction)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .transition(.opacity.combined(with: .scale(scale: 0.86)))
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
    .animation(.easeOut(duration: 0.2), value: volumeButtonLevel == nil)
    .onChange(of: systemVolume.buttonChange) { _, change in
      guard let change, swipeAdjustment == nil else { return }
      volumeButtonLevel = PlayerSwipeAdjustmentState(kind: .volume, fraction: change.fraction)
    }
    .task(id: systemVolume.buttonChange) {
      guard systemVolume.buttonChange != nil else { return }
      try? await Task.sleep(for: .seconds(1.2))
      guard !Task.isCancelled else { return }
      volumeButtonLevel = nil
    }
  }
}
