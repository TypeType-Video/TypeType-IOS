import Foundation

extension DemoSessionStore {
  func presentPlayback(_ video: DemoVideo) {
    let opensNewVideo = activeVideo?.id != video.id
    if opensNewVideo {
      activeVideo = video
      playerController.seek(to: 0)
    }
    isMiniPlayerVisible = false
    if opensNewVideo || playerController.state == .idle {
      playerController.start()
    }
    recordInHistory(video)
  }

  func collapsePlayback(for videoID: String) {
    guard activeVideo?.id == videoID else { return }
    isMiniPlayerVisible = true
  }

  func closePlayback() {
    playerController.stop()
    activeVideo = nil
    isMiniPlayerVisible = false
  }

  func updateProfile(
    username: String,
    displayName: String,
    email: String,
    bio: String
  ) {
    profileUsername = username
    profileDisplayName = displayName
    profileEmail = email
    profileBio = bio
  }

  func useProfileEmoji(_ emoji: String?) {
    profileEmoji = emoji
    profileAvatarData = nil
  }

  func useProfilePhoto(_ data: Data) {
    profileAvatarData = data
    profileEmoji = nil
  }

  func completeDownload(for video: DemoVideo) {
    if let index = downloads.firstIndex(where: { $0.id == video.id }) {
      downloads[index].progress = 1
      downloads[index].phase = "ready"
      downloads[index].errorMessage = nil
      return
    }
    downloads.append(
      DemoDownloadItem(
        id: video.id,
        title: video.title,
        artwork: video.artwork,
        progress: 1,
        phase: "ready"
      )
    )
  }

  func submitMockIssue(
    title: String,
    category: String,
    detail: String,
    diagnostics: String
  ) {
    adminIssues.insert(
      DemoAdminIssue(
        id: "BUG-\(200 + adminIssues.count)",
        title: title,
        category: category,
        status: "Open",
        reporter: profileEmail,
        detail: detail,
        diagnostics: diagnostics,
        githubIssue: nil
      ),
      at: 0
    )
  }

  func clearHistory() {
    historyEntries.removeAll()
    playbackProgressVideoIDs.removeAll()
  }

  func clearSearchHistory() {
    recentSearches.removeAll()
  }

  func applyMockImport(from source: DemoImportSource) {
    followedChannelIDs.formUnion(DemoSubscriptionCatalog.channels.map(\.id))
    let title = "Imported from \(source.shortName)"
    if !playlists.contains(where: { $0.title == title }) {
      let playlistID = createPlaylist(
        named: title,
        artwork: source == .youtube ? .television : .pipePipe
      )
      for video in DemoSearchCatalog.videos.prefix(4) {
        setVideo(video.id, in: playlistID, isIncluded: true)
      }
    }
    for video in DemoMockCatalog.continueWatching.reversed() {
      playbackProgressVideoIDs.insert(video.id)
      historyEntries.removeAll { $0.video.id == video.id }
      historyEntries.insert(
        DemoHistoryEntry(
          video: video,
          watchedAt: "Imported just now · \(source.shortName)",
          group: .today
        ),
        at: 0
      )
    }
  }

  private func recordInHistory(_ video: DemoVideo) {
    guard preferences.tracksHistory else { return }
    playbackProgressVideoIDs.insert(video.id)
    historyEntries.removeAll { $0.video.id == video.id }
    historyEntries.insert(
      DemoHistoryEntry(
        video: video,
        watchedAt: "Watching now · local session",
        group: .today
      ),
      at: 0
    )
  }
}
