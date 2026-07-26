import SwiftUI

struct LiveHistoryFilterBar: View {
  let filter: LiveHistoryFilter
  let count: Int
  let onSelect: (LiveHistoryFilter) -> Void
  let onOlder: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Text("\(count) \(count == 1 ? "video" : "videos")")
        .font(.caption)
        .foregroundStyle(.secondary)

      Spacer()

      Menu {
        Button("All dates") { onSelect(.all) }
        Button("Today") { onSelect(.today) }
        Button("This week") { onSelect(.week) }
        Button("This month") { onSelect(.month) }
        Button("Choose a date...", action: onOlder)
      } label: {
        Label(filter.title, systemImage: "calendar")
          .font(.subheadline.weight(.medium))
      }
      .accessibilityIdentifier("live.history.filter")
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
  }
}
