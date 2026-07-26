import SwiftUI

struct DemoSearchChannelDetailView: View {
  @EnvironmentObject var session: DemoSessionStore
  @Environment(\.colorScheme) var colorScheme
  let channel: DemoSearchChannel
  @State var selectedSection = "Videos"
  @State var selectedVideo: DemoVideo?
  @State var selectedPlaylist: DemoPlaylist?
  @State var query = ""
  @State var sortOrder = "Newest"
  @State var channelState = "Normal"
  @State var visibleVideoCount = 4

  init(channel: DemoSearchChannel) {
    self.channel = channel
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        channelContent
      }
      .padding(16)
    }
    .background(pageBackground)
    .preferredColorScheme(session.preferences.colorScheme)
    .navigationTitle("Channel")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .navigationDestination(item: $selectedVideo) { video in
      DemoWatchView(video: video)
    }
    .navigationDestination(item: $selectedPlaylist) { playlist in
      DemoSearchPlaylistDetailView(playlist: playlist)
    }
    .onChange(of: query) { visibleVideoCount = 4 }
    .onChange(of: sortOrder) { visibleVideoCount = 4 }
    .onChange(of: selectedSection) {
      query = ""
      visibleVideoCount = 4
    }
  }

  var filteredVideos: [DemoVideo] {
    Array(sortedChannelVideos.prefix(visibleVideoCount))
  }

  var sortedChannelVideos: [DemoVideo] {
    let source = DemoChannelCatalog.videos(for: channel)
    let filtered = query.isEmpty
      ? source
      : source.filter {
          $0.title.localizedCaseInsensitiveContains(query)
            || $0.channel.localizedCaseInsensitiveContains(query)
        }

    switch sortOrder {
    case "Popular":
      return filtered.sorted {
        DemoChannelCatalog.popularityScore(for: $0)
          > DemoChannelCatalog.popularityScore(for: $1)
      }
    case "Oldest":
      return Array(filtered.reversed())
    default:
      return filtered
    }
  }

  var canLoadMoreVideos: Bool {
    visibleVideoCount < sortedChannelVideos.count
  }

  var pageBackground: Color {
    colorScheme == .dark
      ? Color(red: 0.025, green: 0.026, blue: 0.032)
      : Color(red: 0.97, green: 0.97, blue: 0.985)
  }

  var secondarySurface: Color {
    colorScheme == .dark
      ? Color.white.opacity(0.085)
      : Color.black.opacity(0.065)
  }

  var searchSecondaryText: Color {
    colorScheme == .dark
      ? Color.white.opacity(0.68)
      : Color.black.opacity(0.58)
  }
}
