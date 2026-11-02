import SwiftUI

struct LiveRefusedRecommendationCard: View {
  let state: LiveRecommendationRefusals.State
  let videoTitle: String
  let onExplain: (LiveRefusalReason) -> Void
  let onUndo: () -> Void
  @Environment(\.themePalette) private var palette

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      if let reason = chosenReason {
        Label {
          Text("Noted: \(Text(reason.title))")
        } icon: {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(palette.accent)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(palette.textPrimary)
        .padding(.horizontal, 12)
        .frame(minHeight: 34)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .leading)))
      } else {
        reasons
          .transition(.opacity)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    .animation(.smooth(duration: 0.25), value: state)
    .sensoryFeedback(.selection, trigger: chosenReason)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("live.home.refused-card")
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: "hand.thumbsdown.fill")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(palette.accent)
        .frame(width: 36, height: 36)
        .background(palette.accent.opacity(0.14), in: Circle())
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text("Removed from your recommendations")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(palette.textPrimary)
          .lineLimit(2)
        Text(verbatim: videoTitle)
          .font(.caption)
          .foregroundStyle(palette.textSecondary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      undoButton
    }
  }

  @ViewBuilder
  private var undoButton: some View {
    if case .withdrawing = state {
      ProgressView()
        .frame(minWidth: 44, minHeight: 32)
    } else {
      Button(action: onUndo) {
        Text("Undo")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(palette.accent)
          .padding(.horizontal, 14)
          .frame(minHeight: 32)
          .background(palette.accent.opacity(0.14), in: Capsule())
      }
      .buttonStyle(.plain)
      .disabled(!isSaved)
      .accessibilityHint("Puts this video back in your recommendations")
    }
  }

  private var reasons: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Why? (if you wish)")
        .font(.caption.weight(.medium))
        .foregroundStyle(palette.textSecondary)
      LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
        ForEach(LiveRefusalReason.allCases) { reason in
          Button {
            onExplain(reason)
          } label: {
            Text(reason.title)
              .font(.footnote.weight(.medium))
              .foregroundStyle(palette.textPrimary)
              .lineLimit(1)
              .minimumScaleFactor(0.75)
              .padding(.horizontal, 10)
              .frame(maxWidth: .infinity, minHeight: 34)
              .background(Color.primary.opacity(0.06), in: Capsule())
          }
          .buttonStyle(.plain)
          .disabled(!isSaved)
          .opacity(isSaved ? 1 : 0.5)
        }
      }
    }
  }

  private var chosenReason: LiveRefusalReason? {
    if case let .saved(_, reason) = state { return reason }
    return nil
  }

  private var isSaved: Bool {
    if case .saved = state { return true }
    return false
  }
}
