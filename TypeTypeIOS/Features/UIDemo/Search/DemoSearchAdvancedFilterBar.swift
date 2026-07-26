import SwiftUI

struct DemoSearchAdvancedFilterBar: View {
  @Binding var service: DemoSearchService
  @Binding var content: DemoSearchContentFilter
  @Binding var sort: DemoSearchSort

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        selectionMenu(
          title: service.rawValue,
          symbol: "network",
          values: DemoSearchService.allCases,
          selection: $service
        )
        selectionMenu(
          title: content.rawValue,
          symbol: "line.3.horizontal.decrease.circle",
          values: availableContentFilters,
          selection: $content
        )
        selectionMenu(
          title: sort.rawValue,
          symbol: "arrow.up.arrow.down",
          values: DemoSearchSort.allCases,
          selection: $sort
        )
      }
      .padding(.horizontal, 16)
    }
    .scrollIndicators(.hidden)
    .onChange(of: service) {
      if !availableContentFilters.contains(content) {
        content = .all
      }
    }
    .accessibilityIdentifier("demo.search.advanced-filters")
  }

  private var availableContentFilters: [DemoSearchContentFilter] {
    switch service {
    case .youtube:
      return [
        .all,
        .videos,
        .live,
        .music,
        .musicVideos,
        .albums,
        .musicPlaylists,
        .artists,
      ]
    case .nicoNico:
      return [.all, .videos, .live, .music, .musicVideos]
    case .biliBili:
      return [.all, .videos, .series, .live]
    }
  }

  private func selectionMenu<Value: Identifiable & Hashable & RawRepresentable>(
    title: String,
    symbol: String,
    values: [Value],
    selection: Binding<Value>
  ) -> some View where Value.RawValue == String {
    Menu {
      ForEach(values) { value in
        Button {
          selection.wrappedValue = value
        } label: {
          if selection.wrappedValue == value {
            Label(value.rawValue, systemImage: "checkmark")
          } else {
            Text(value.rawValue)
          }
        }
      }
    } label: {
      Label(title, systemImage: symbol)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(DemoTheme.surface)
        .clipShape(Capsule())
    }
  }
}
