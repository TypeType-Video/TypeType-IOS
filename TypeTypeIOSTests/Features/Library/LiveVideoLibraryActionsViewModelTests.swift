import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveVideoLibraryActionsViewModelTests: XCTestCase {
  func testPrepareAndAllVideoMutationsStaySynchronized() async {
    let video = LiveVideoItemFixture.make()
    let library = LiveLibraryServiceStub()
    library.favoriteItems = [LiveLibraryFixtures.favorite(url: video.url)]
    let playlists = LivePlaylistsServiceStub()
    playlists.playlistItems = [LiveLibraryFixtures.playlist()]
    let viewModel = LiveVideoLibraryActionsViewModel(
      video: video,
      library: library,
      playlistService: playlists
    )

    await viewModel.prepare()
    XCTAssertTrue(viewModel.isFavorite)
    XCTAssertFalse(viewModel.isInWatchLater)
    XCTAssertEqual(viewModel.playlists.count, 1)

    await viewModel.toggleFavorite()
    await viewModel.toggleWatchLater()
    await viewModel.toggle(viewModel.playlists[0])

    XCTAssertFalse(viewModel.isFavorite)
    XCTAssertTrue(viewModel.isInWatchLater)
    XCTAssertTrue(viewModel.contains(viewModel.playlists[0]))
  }

  func testCreatePlaylistAddsCurrentVideo() async {
    let video = LiveVideoItemFixture.make()
    let library = LiveLibraryServiceStub()
    let playlists = LivePlaylistsServiceStub()
    let viewModel = LiveVideoLibraryActionsViewModel(
      video: video,
      library: library,
      playlistService: playlists
    )

    await viewModel.prepare()
    let created = await viewModel.createPlaylist(
      name: "New",
      description: "Native"
    )

    XCTAssertTrue(created)
    XCTAssertEqual(viewModel.playlists.map(\.name), ["New"])
    XCTAssertTrue(viewModel.contains(viewModel.playlists[0]))
  }
}
