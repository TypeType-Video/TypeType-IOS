import SwiftUI

struct WatchRelatedSection: View {
  let related: [HomeVideoItem]
  let coordinator: RootCoordinator
  let watchService: WatchServiceProtocol
  let watchProgressService: WatchProgressServiceProtocol
  let watchActionsService: WatchActionsServiceProtocol
  @State private var filteredRelated: [HomeVideoItem] = []

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Related")
        .font(.headline)

      if filteredRelated.isEmpty {
        Text("No related videos")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        ForEach(filteredRelated.prefix(6)) { video in
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
    .task(id: related.map(\.id).joined(separator: ":")) {
      do {
        async let blockedChannelsReq = coordinator.dependencies.blockedService.channels()
        async let blockedVideosReq = coordinator.dependencies.blockedService.videos()
        let blockedChannels = try await blockedChannelsReq
        let blockedVideos = try await blockedVideosReq
        filteredRelated = BlockedFilter.apply(
          to: related,
          blockedChannels: Set(blockedChannels.map(\.url)),
          blockedVideos: Set(blockedVideos.map(\.url))
        )
      } catch {
        filteredRelated = related
      }
    }
  }
}
