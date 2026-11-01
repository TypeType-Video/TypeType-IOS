import SwiftUI

struct LiveRefusedRecommendationCard: View {
  let state: LiveRecommendationRefusals.State
  let onExplain: (LiveRefusalReason) -> Void
  let onUndo: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Removed from your recommendations", systemImage: "hand.thumbsdown")
        .font(.subheadline.weight(.semibold))
      if case let .saved(_, reason) = state, reason != nil {
        Text("Noted, thank you")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        reasons
      }
      Button("Undo", action: onUndo)
        .font(.subheadline.weight(.semibold))
        .disabled(!isSaved)
        .accessibilityHint("Puts this video back in your recommendations")
    }
    .padding(20)
    .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("live.home.refused-card")
  }

  private var reasons: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Why? (if you wish)")
        .font(.footnote)
        .foregroundStyle(.secondary)
      LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
        ForEach(LiveRefusalReason.allCases) { reason in
          Button {
            onExplain(reason)
          } label: {
            Text(reason.title)
              .font(.footnote.weight(.medium))
              .lineLimit(1)
              .minimumScaleFactor(0.8)
              .frame(maxWidth: .infinity, minHeight: 32)
          }
          .buttonStyle(.bordered)
          .disabled(!isSaved)
        }
      }
    }
  }

  private var isSaved: Bool {
    if case .saved = state { return true }
    return false
  }
}
