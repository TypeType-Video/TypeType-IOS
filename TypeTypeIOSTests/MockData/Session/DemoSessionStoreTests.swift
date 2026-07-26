import AVFoundation
import XCTest
@testable import TypeTypeIOS

@MainActor
final class DemoSessionStoreTests: XCTestCase {
  func testFavoriteAndWatchLaterMutationsAreReversible() {
    let store = DemoSessionStore()
    let videoID = "native-ios"

    XCTAssertFalse(store.favoriteVideoIDs.contains(videoID))
    XCTAssertFalse(store.watchLaterVideoIDs.contains(videoID))

    store.toggleFavorite(videoID)
    store.toggleWatchLater(videoID)

    XCTAssertTrue(store.favoriteVideoIDs.contains(videoID))
    XCTAssertTrue(store.watchLaterVideoIDs.contains(videoID))

    store.toggleFavorite(videoID)
    store.toggleWatchLater(videoID)

    XCTAssertFalse(store.favoriteVideoIDs.contains(videoID))
    XCTAssertFalse(store.watchLaterVideoIDs.contains(videoID))
  }

  func testQueueKeepsMembershipAndOrderInSync() {
    let store = DemoSessionStore()
    guard let firstID = store.queueOrder.first else {
      return XCTFail("Expected a seeded queue")
    }

    store.toggleQueue(firstID)
    XCTAssertFalse(store.queuedVideoIDs.contains(firstID))
    XCTAssertFalse(store.queueOrder.contains(firstID))

    store.toggleQueue(firstID)
    XCTAssertEqual(store.queueOrder.last, firstID)
    XCTAssertTrue(store.queuedVideoIDs.contains(firstID))

    store.moveQueuedVideo(firstID, offset: -1)
    XCTAssertNotEqual(store.queueOrder.last, firstID)

    store.clearQueue()
    XCTAssertTrue(store.queuedVideoIDs.isEmpty)
    XCTAssertTrue(store.queueOrder.isEmpty)
  }

  func testImportCreatesVisiblePlaylistAndHistory() {
    let store = DemoSessionStore()

    store.clearHistory()
    store.applyMockImport(from: .youtube)

    let playlist = store.playlists.first {
      $0.title == "Imported from YouTube"
    }
    XCTAssertNotNil(playlist)
    XCTAssertEqual(store.playlistVideoIDs[playlist?.id ?? ""]?.count, 4)
    XCTAssertFalse(store.historyEntries.isEmpty)
    XCTAssertTrue(
      store.historyEntries.allSatisfy {
        $0.watchedAt.contains("Imported just now")
      }
    )
    XCTAssertFalse(store.playbackProgressVideoIDs.isEmpty)
  }

  func testClearingHistoryAlsoClearsPlaybackProgress() {
    let store = DemoSessionStore()

    XCTAssertFalse(store.historyEntries.isEmpty)
    XCTAssertFalse(store.playbackProgressVideoIDs.isEmpty)
    store.clearHistory()

    XCTAssertTrue(store.historyEntries.isEmpty)
    XCTAssertTrue(store.playbackProgressVideoIDs.isEmpty)
  }

  func testSystemPlaylistsCannotBeDeleted() {
    let store = DemoSessionStore()

    store.deletePlaylist("favorites")
    store.deletePlaylist("watch-later")

    XCTAssertTrue(store.playlists.contains { $0.id == "favorites" })
    XCTAssertTrue(store.playlists.contains { $0.id == "watch-later" })
  }

  func testPreferenceMutationPublishesUpdatedValue() {
    let store = DemoSessionStore()

    store.setPreference(\.showsRecommendations, to: false)
    store.setPreference(\.tracksHistory, to: false)

    XCTAssertFalse(store.preferences.showsRecommendations)
    XCTAssertFalse(store.preferences.tracksHistory)
  }

  func testReopeningPausedVideoDoesNotRestartPlayback() {
    let store = DemoSessionStore()
    let video = DemoMockCatalog.continueWatching[0]

    store.presentPlayback(video)
    let initialStarts = store.playerController.playbackStartSequence
    store.playerController.stop()
    store.collapsePlayback(for: video.id)
    store.presentPlayback(video)

    XCTAssertEqual(
      store.playerController.playbackStartSequence,
      initialStarts
    )
    XCTAssertFalse(store.isMiniPlayerVisible)
  }

  func testOpeningDifferentVideoStartsPlayback() {
    let store = DemoSessionStore()
    let first = DemoMockCatalog.continueWatching[0]
    let second = DemoMockCatalog.continueWatching[1]

    store.presentPlayback(first)
    let initialStarts = store.playerController.playbackStartSequence
    store.presentPlayback(second)

    XCTAssertEqual(
      store.playerController.playbackStartSequence,
      initialStarts + 1
    )
    XCTAssertEqual(store.activeVideo?.id, second.id)
  }

  func testAudioBoostClampsToVidstackRange() {
    let controller = DemoPlayerController()

    controller.setAudioGain(percent: 450)
    XCTAssertEqual(controller.audioGainPercent, 300)
    controller.setAudioGain(percent: 40)
    XCTAssertEqual(controller.audioGainPercent, 100)
  }

  func testAudioBoostCreatesNativeProcessingTap() {
    XCTAssertNotNil(DemoAudioGainProcessor.makeTap(gain: 2))
  }

  func testBundledDemoMovieIsPlayableByAVPlayer() async throws {
    let url = DemoBigBuckBunnySource.videoURL
    XCTAssertTrue(url.isFileURL)

    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.play()
    for _ in 0..<80
    where item.status != .failed && player.timeControlStatus != .playing {
      try await Task.sleep(for: .milliseconds(100))
    }

    XCTAssertEqual(
      item.status,
      .readyToPlay,
      item.error?.localizedDescription ?? "No AVPlayerItem error"
    )
    XCTAssertEqual(
      player.timeControlStatus,
      .playing,
      player.reasonForWaitingToPlay?.rawValue ?? "No waiting reason"
    )
    player.pause()
  }

  func testPublicPlaylistRestoreRestoresSavedMembership() throws {
    let store = DemoSessionStore()
    let playlist = try XCTUnwrap(
      store.playlists.first { $0.id == "pipepipe" }
    )

    store.deletePlaylist(playlist.id)
    XCTAssertFalse(store.savedPublicPlaylistIDs.contains(playlist.id))

    store.restorePlaylist(playlist)
    XCTAssertTrue(store.playlists.contains { $0.id == playlist.id })
    XCTAssertTrue(store.savedPublicPlaylistIDs.contains(playlist.id))
  }

  func testDeArrowBrandingChangesTitleAndThumbnail() {
    let video = DemoMockCatalog.continueWatching[0]
    var preferences = DemoSessionPreferences()
    preferences.deArrow = true

    let community = video.branded(using: preferences)
    XCTAssertEqual(community.title, "A giant rabbit chooses kindness")
    XCTAssertEqual(community.artwork, .dog)

    preferences.deArrowTitleMode = "Original title"
    preferences.deArrowThumbnailMode = "Original thumbnail"
    let original = video.branded(using: preferences)
    XCTAssertEqual(original.title, video.title)
    XCTAssertEqual(original.artwork, video.artwork)
  }

  func testDeArrowLockedPolicyRejectsUnlockedCommunityEntry() {
    let video = DemoMockCatalog.continueWatching[1]
    var preferences = DemoSessionPreferences()
    preferences.deArrow = true
    preferences.deArrowTrustMode = "Locked entries only"
    preferences.deArrowThumbnailMode = "Community only"

    let branded = video.branded(using: preferences)

    XCTAssertEqual(branded.title, video.title)
    XCTAssertEqual(branded.artwork, video.artwork)
  }

  func testAdminAndPrivacyMutationsAffectSharedMockState() {
    let store = DemoSessionStore()

    store.isInstanceAllowListRestricted = true
    store.globalAllowedChannels = ["Blender Studio"]
    store.toggleBlockedVideo("native-ios")
    store.clearSearchHistory()
    store.clearHistory()

    XCTAssertTrue(store.isInstanceAllowListRestricted)
    XCTAssertEqual(store.globalAllowedChannels, ["Blender Studio"])
    XCTAssertTrue(store.blockedVideoIDs.contains("native-ios"))
    XCTAssertTrue(store.recentSearches.isEmpty)
    XCTAssertTrue(store.historyEntries.isEmpty)
  }
}
