import SwiftUI

struct LiveRefusedRecommendationCard: View {
  let state: LiveRecommendationRefusals.State
  let onUndo: () -> Void

  var body: some View {
    Color.clear
      .aspectRatio(16 / 9, contentMode: .fit)
      .overlay(alignment: .leading) {
        VStack(alignment: .leading, spacing: 12) {
          Label("Removed from your recommendations", systemImage: "hand.thumbsdown")
            .font(.subheadline.weight(.semibold))
          Button("Undo", action: onUndo)
            .font(.subheadline.weight(.semibold))
            .disabled(!canUndo)
            .accessibilityHint("Puts this video back in your recommendations")
        }
        .padding(20)
      }
      .background {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("live.home.refused-card")
  }

  private var canUndo: Bool {
    if case .saved = state { return true }
    return false
  }
}
