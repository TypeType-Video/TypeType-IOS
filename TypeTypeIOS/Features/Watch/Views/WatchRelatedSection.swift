import SwiftUI

struct WatchRelatedSection: View {
  let related: [HomeVideoItem]
  let coordinator: RootCoordinator
  let watchService: WatchServiceProtocol
  let watchProgressService: WatchProgressServiceProtocol
  let watchActionsService: WatchActionsServiceProtocol

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Related")
        .font(.headline)

      if related.isEmpty {
        Text("No related videos")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        ForEach(related.prefix(6)) { video in
          NavigationLink {
            WatchView(
              videoURL: video.url,
              coordinator: coordinator,
              watchService: watchService,
              watchProgressService: watchProgressService,
              watchActionsService: watchActionsService
            )
          } label: {
            HomeVideoRowView(video: video)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}
