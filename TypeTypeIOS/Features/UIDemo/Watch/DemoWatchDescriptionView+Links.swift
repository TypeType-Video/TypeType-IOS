import SwiftUI

extension DemoWatchDescriptionView {
  var metadata: some View {
    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
      GridRow {
        Text("License").foregroundStyle(.secondary)
        Text("Creative Commons BY 3.0")
      }
      GridRow {
        Text("Category").foregroundStyle(.secondary)
        Text("Film & Animation")
      }
      GridRow {
        Text("Language").foregroundStyle(.secondary)
        Text("No dialogue")
      }
      GridRow {
        Text("Source").foregroundStyle(.secondary)
        Text("Blender Foundation")
      }
    }
    .font(.caption)
  }

  var externalLinks: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 10) {
        linkButton("YouTube", symbol: "play.rectangle.fill", url: DemoWatchLinkCatalog.youtube)
        linkButton("NicoNico", symbol: "tv", url: DemoWatchLinkCatalog.nicoNico)
        linkButton("BiliBili", symbol: "play.tv", url: DemoWatchLinkCatalog.biliBili)
        linkButton(
          "Project page",
          symbol: "safari",
          url: DemoBigBuckBunnySource.projectURL
        )
        linkButton(
          "Blender",
          symbol: "arrow.up.right",
          url: DemoBigBuckBunnySource.blenderProjectsURL
        )
      }
    }
    .scrollIndicators(.hidden)
  }

  private func linkButton(
    _ title: String,
    symbol: String,
    url: URL
  ) -> some View {
    Button {
      onOpenURL(url)
    } label: {
      Label(title, systemImage: symbol)
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 11)
        .frame(height: 36)
        .background(DemoTheme.elevatedSurface)
        .clipShape(Capsule())
    }
    .buttonStyle(.plain)
  }
}
