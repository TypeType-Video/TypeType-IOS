import XCTest
@testable import TypeTypeIOS

@MainActor
final class LivePlaylistsViewModelTests: XCTestCase {
  func testLoadAndMutationsKeepAllLibrarySectionsCurrent() async {
    let playlists = LivePlaylistsServiceStub()
    playlists.playlistItems = [LiveLibraryFixtures.playlist()]
    playlists.savedItems = [LiveLibraryFixtures.saved()]
    let library = LiveLibraryServiceStub()
    library.favoriteItems = [LiveLibraryFixtures.favorite()]
    library.watchLaterItems = [LiveLibraryFixtures.watchLater()]
    let viewModel = LivePlaylistsViewModel(
      playlistsService: playlists,
      libraryService: library
    )

    await viewModel.reload()

    XCTAssertEqual(viewModel.state, .loaded)
    XCTAssertEqual(viewModel.playlists.count, 1)
    XCTAssertEqual(viewModel.saved.count, 1)
    XCTAssertEqual(viewModel.favorites.count, 1)
    XCTAssertEqual(viewModel.watchLater.count, 1)

    let created = await viewModel.create(name: "New", description: "List")
    XCTAssertTrue(created)
    await viewModel.delete(viewModel.playlists[0])
    await viewModel.removeSaved(viewModel.saved[0])

    XCTAssertEqual(viewModel.playlists.map(\.name), ["New"])
    XCTAssertTrue(viewModel.saved.isEmpty)
  }
}
