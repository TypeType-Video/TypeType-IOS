import SwiftUI

struct DemoMoreContentSection: View {
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    DemoMoreSectionCard("Content") {
      NavigationLink {
        DemoPodcastsView()
      } label: {
        row(
          "Podcasts",
          subtitle: "Open Playback · \(DemoPodcastEpisode.all.count) episodes",
          systemImage: "mic.fill",
          tint: .purple
        )
      }
      .buttonStyle(.plain)
      divider
      NavigationLink {
        DemoDownloadsView()
      } label: {
        row(
          "Downloads",
          subtitle: downloadSummary,
          systemImage: "arrow.down.circle.fill",
          tint: .blue
        )
      }
      .buttonStyle(.plain)
      divider
      NavigationLink {
        DemoImportView()
      } label: {
        row(
          "Import",
          subtitle: "YouTube and PipePipe",
          systemImage: "square.and.arrow.down",
          tint: .orange
        )
      }
      .buttonStyle(.plain)
    }
  }

  private var divider: some View {
    Divider().padding(.leading, 45)
  }

  private var downloadSummary: String {
    let ready = session.downloads.filter { $0.phase == "ready" }.count
    let active = session.downloads.filter { $0.phase == "running" }.count
    let failed = session.downloads.filter { $0.phase == "failed" }.count
    return "\(ready) ready · \(active) active · \(failed) failed"
  }

  private func row(
    _ title: String,
    subtitle: String? = nil,
    systemImage: String,
    tint: Color
  ) -> some View {
    DemoMoreRow(
      title,
      subtitle: subtitle,
      systemImage: systemImage,
      tint: tint,
      showsChevron: true
    )
    .padding(.vertical, 11)
  }
}
