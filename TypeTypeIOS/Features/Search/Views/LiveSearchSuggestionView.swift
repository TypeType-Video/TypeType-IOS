import SwiftUI

struct LiveSearchSuggestionView: View {
  let query: String
  let suggestion: String
  let isCorrected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: "text.magnifyingglass")
        VStack(alignment: .leading, spacing: 2) {
          Text(isCorrected ? "Showing corrected results" : "Did you mean?")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(suggestion)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
          if isCorrected {
            Text("Search instead for “\(query)”")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(13)
      .background(
        DemoTheme.accent.opacity(0.12),
        in: RoundedRectangle(cornerRadius: 14)
      )
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("live.search.suggestion")
  }
}
