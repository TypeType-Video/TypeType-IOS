import SwiftUI

extension DemoSearchView {
  var discovery: some View {
    VStack(alignment: .leading, spacing: 26) {
      searchPrompt
      querySection(
        title: "Recent searches",
        symbol: "clock.arrow.circlepath",
        values: session.recentSearches,
        allowsRemoval: true
      )
      querySection(
        title: "Trending in your instance",
        symbol: "chart.line.uptrend.xyaxis",
        values: DemoSearchCatalog.trendingQueries,
        allowsRemoval: false
      )
    }
  }

  var searchPrompt: some View {
    HStack(spacing: 14) {
      Image(systemName: "magnifyingglass")
        .font(.title2.weight(.medium))
        .foregroundStyle(Color(red: 1, green: 0.31, blue: 0.34))
        .frame(width: 46, height: 46)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

      VStack(alignment: .leading, spacing: 4) {
        Text("Find your next video")
          .font(.headline)
        Text("Search videos, channels, and playlists across your selected service.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 16)
  }

  func querySection(
    title: String,
    symbol: String,
    values: [String],
    allowsRemoval: Bool
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label(title, systemImage: symbol)
          .font(.subheadline.weight(.semibold))
        Spacer()
        if allowsRemoval && !values.isEmpty {
          Button("Clear") {
            withAnimation(.snappy) {
              session.recentSearches.removeAll()
            }
          }
          .font(.caption.weight(.medium))
        }
      }
      .padding(.horizontal, 16)

      if values.isEmpty {
        Text("Your searches will appear here.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 16)
      } else {
        VStack(spacing: 0) {
          ForEach(values, id: \.self) { value in
            Button {
              query = value
              rememberQuery()
            } label: {
              HStack(spacing: 12) {
                Image(systemName: allowsRemoval ? "clock" : "arrow.up.right")
                  .foregroundStyle(.secondary)
                  .frame(width: 22)
                Text(value)
                  .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.left")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .padding(.horizontal, 16)
              .frame(minHeight: 48)
            }
            .buttonStyle(.plain)
            if value != values.last {
              Divider().padding(.leading, 50)
            }
          }
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
      }
    }
  }
}
