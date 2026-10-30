import SwiftUI

struct LiveSearchSuggestionsList: View {
  let suggestions: [String]
  let onSearch: (String) -> Void
  let onFill: (String) -> Void

  var body: some View {
    List {
      LiveSection {
        ForEach(suggestions, id: \.self) { suggestion in
          HStack(spacing: 12) {
            Button {
              onSearch(suggestion)
            } label: {
              Label {
                Text(suggestion)
                  .foregroundStyle(.primary)
                  .lineLimit(1)
              } icon: {
                Image(systemName: "magnifyingglass")
                  .foregroundStyle(.secondary)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
              onFill(suggestion)
            } label: {
              Image(systemName: "arrow.up.left")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Edit \(suggestion)"))
          }
        }
      }
    }
    .liveGroupedList()
    .contentMargins(.top, 0, for: .scrollContent)
    .scrollDismissesKeyboard(.immediately)
    .accessibilityIdentifier("live.search.suggestions")
  }
}
