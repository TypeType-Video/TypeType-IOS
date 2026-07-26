import Foundation

extension DemoSearchView {
  var normalizedQuery: String {
    query.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var videos: [DemoVideo] {
    let matched = DemoSearchCatalog.matchedVideos(for: normalizedQuery)
      .filter { DemoSearchCatalog.service(for: $0.id) == selectedService }
      .filter {
        DemoSearchCatalog.contentMatches(contentFilter, videoID: $0.id)
      }
      .filter(isVisible)
    switch sortOrder {
    case .relevance:
      return matched
    case .newest:
      return Array(matched.reversed())
    case .views:
      return matched.sorted { $0.id > $1.id }
    }
  }

  var channels: [DemoSearchChannel] {
    DemoSearchCatalog.matchedChannels(for: normalizedQuery)
      .filter {
        !session.blockedChannelNames.contains($0.name)
          && (
            !session.isInstanceAllowListRestricted
              || session.globalAllowedChannels.contains($0.name)
          )
      }
  }

  var playlists: [DemoPlaylist] {
    let matched = DemoSearchCatalog.matchedPlaylists(for: normalizedQuery)
      .filter {
        !session.isInstanceAllowListRestricted
          || session.globalAllowedPlaylists.contains($0.title)
      }
    if contentFilter == .musicPlaylists {
      return matched.filter { $0.id == "open-audio" }
    }
    return contentFilter == .all ? matched : []
  }

  var visibleVideos: [DemoVideo] {
    Array(videos.prefix(visibleVideoCount))
  }

  var canLoadMoreVideos: Bool {
    visibleVideoCount < videos.count
  }

  var showsVideos: Bool {
    selectedScope == .all || selectedScope == .videos
  }

  var showsChannels: Bool {
    selectedScope == .all || selectedScope == .channels
  }

  var showsPlaylists: Bool {
    selectedScope == .all || selectedScope == .playlists
  }

  var totalResultCount: Int {
    (showsVideos ? videos.count : 0)
      + (showsChannels ? channels.count : 0)
      + (showsPlaylists ? playlists.count : 0)
  }

  func rememberQuery() {
    let value = normalizedQuery
    guard !value.isEmpty else { return }
    session.recentSearches.removeAll {
      $0.caseInsensitiveCompare(value) == .orderedSame
    }
    session.recentSearches.insert(value, at: 0)
    session.recentSearches = Array(session.recentSearches.prefix(6))
  }

  func resetPagination() {
    visibleVideoCount = 4
    isLoadingMore = false
  }

  func isVisible(_ video: DemoVideo) -> Bool {
    !session.hiddenVideoIDs.contains(video.id)
      && !session.blockedVideoIDs.contains(video.id)
      && !session.blockedChannelNames.contains(video.channel)
      && (
        !session.isInstanceAllowListRestricted
          || session.globalAllowedChannels.contains(video.channel)
      )
  }

  func loadMoreVideos() {
    guard canLoadMoreVideos, !isLoadingMore else { return }
    isLoadingMore = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(450))
      visibleVideoCount = min(visibleVideoCount + 4, videos.count)
      isLoadingMore = false
    }
  }
}
