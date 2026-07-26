import Combine
import Foundation

@MainActor
final class DemoSessionStore: ObservableObject {
  let playerController = DemoPlayerController()

  @Published var favoriteVideoIDs: Set<String> = ["big-buck-bunny"]
  @Published var watchLaterVideoIDs: Set<String> = ["private-home"]
  @Published var queuedVideoIDs: Set<String>
  @Published var queueOrder: [String]
  @Published var hiddenVideoIDs: Set<String> = []
  @Published var blockedVideoIDs: Set<String> = []
  @Published var blockedChannelNames: Set<String> = []
  @Published var followedChannelIDs: Set<String>
  @Published var savedPublicPlaylistIDs: Set<String>
  @Published var playlists = DemoPlaylistCatalog.initial
  @Published var playlistVideoIDs: [String: Set<String>] = [
    "open-movies": ["big-buck-bunny", "big-buck-restored"],
    "self-hosted": ["private-home"],
  ]
  @Published var activeVideo: DemoVideo?
  @Published var isMiniPlayerVisible = false
  @Published var profileUsername = "typetype"
  @Published var profileDisplayName = "TypeType"
  @Published var profileEmail = "demo@typetype.video"
  @Published var profileBio =
    "An open-source video client built with the community."
  @Published var profileEmoji: String?
  @Published var profileAvatarData: Data?
  @Published var downloads = DemoDownloadItem.initial
  @Published var preferences = DemoSessionPreferences()
  @Published var historyEntries = DemoHistoryCatalog.entries
  @Published var playbackProgressVideoIDs: Set<String>
  @Published var recentSearches = DemoSearchCatalog.recentQueries
  @Published var notifications = DemoNotificationCatalog.initial
  @Published var adminSettings = DemoAdminSettings()
  @Published var adminUsers = DemoAdminUser.initial
  @Published var adminSessions = DemoAdminSession.initial
  @Published var adminIssues = DemoAdminIssue.initial
  @Published var isInstanceAllowListRestricted = false
  @Published var globalAllowedChannels = ["Blender Studio", "TypeType"]
  @Published var globalAllowedPlaylists = ["Open movie night"]
  @Published var restrictedAdminUserIDs: Set<String> = ["user-viewer"]
  @Published var userAllowedChannels: [String: Set<String>] = [:]
  @Published var userAllowedPlaylists: [String: Set<String>] = [:]

  init() {
    let initialQueue = DemoWatchCatalog.queue.map(\.id)
    queuedVideoIDs = Set(initialQueue)
    queueOrder = initialQueue
    playbackProgressVideoIDs = Set(
      DemoMockCatalog.continueWatching.map(\.id)
    )
    followedChannelIDs = Set(DemoSubscriptionCatalog.channels.map(\.id))
    savedPublicPlaylistIDs = Set(
      DemoPlaylistCatalog.initial.filter(\.isPublicSaved).map(\.id)
    )
  }

  func toggleFavorite(_ videoID: String) {
    toggle(videoID, in: &favoriteVideoIDs)
  }

  func toggleWatchLater(_ videoID: String) {
    toggle(videoID, in: &watchLaterVideoIDs)
  }

  func toggleQueue(_ videoID: String) {
    if queuedVideoIDs.contains(videoID) {
      queuedVideoIDs.remove(videoID)
      queueOrder.removeAll { $0 == videoID }
    } else {
      queuedVideoIDs.insert(videoID)
      queueOrder.append(videoID)
    }
  }

  func moveQueuedVideo(_ videoID: String, offset: Int) {
    guard let source = queueOrder.firstIndex(of: videoID) else { return }
    let destination = min(max(0, source + offset), queueOrder.count - 1)
    guard source != destination else { return }
    let value = queueOrder.remove(at: source)
    queueOrder.insert(value, at: destination)
  }

  func clearQueue() {
    queuedVideoIDs.removeAll()
    queueOrder.removeAll()
  }

  func toggleHidden(_ videoID: String) {
    toggle(videoID, in: &hiddenVideoIDs)
  }

  func toggleBlockedVideo(_ videoID: String) {
    toggle(videoID, in: &blockedVideoIDs)
  }

  func toggleBlockedChannel(_ channelName: String) {
    toggle(channelName, in: &blockedChannelNames)
  }

  func toggleFollowedChannel(_ channelID: String) {
    toggle(channelID, in: &followedChannelIDs)
  }

  func toggleSavedPlaylist(_ playlistID: String) {
    toggle(playlistID, in: &savedPublicPlaylistIDs)
  }

  func setPreference<Value>(
    _ keyPath: WritableKeyPath<DemoSessionPreferences, Value>,
    to value: Value
  ) {
    var updated = preferences
    updated[keyPath: keyPath] = value
    preferences = updated
  }

  func toggle<Value: Hashable>(
    _ value: Value,
    in values: inout Set<Value>
  ) {
    if values.contains(value) {
      values.remove(value)
    } else {
      values.insert(value)
    }
  }

  func set<Value: Hashable>(
    _ value: Value,
    in values: inout Set<Value>,
    isIncluded: Bool
  ) {
    if isIncluded {
      values.insert(value)
    } else {
      values.remove(value)
    }
  }
}
