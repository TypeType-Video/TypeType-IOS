import XCTest
@testable import TypeTypeIOS

@MainActor
final class LivePublicPlaylistViewModelTests: XCTestCase {
  func testLoadPaginationIncludesShortsAndTogglesSavedState() async {
    let listURL = "https://video.test/public-list"
    let first = LiveVideoItemFixture.make()
    let duplicate = LiveVideoItemFixture.make(id: "duplicate")
    let short = LiveVideoItemFixture.make(
      id: "short",
      url: "https://video.test/shorts/short",
      isShort: true
    )
    let second = LiveVideoItemFixture.make(
      id: "second",
      url: "https://video.test/second"
    )
    let service = LivePlaylistsServiceStub()
    service.publicPages = [
      LivePublicPlaylistPage(
        playlist: LiveLibraryFixtures.publicResult(url: listURL),
        videos: [first, duplicate, short],
        nextPage: "next"
      ),
      LivePublicPlaylistPage(
        playlist: LiveLibraryFixtures.publicResult(url: listURL),
        videos: [first, second],
        nextPage: nil
      ),
    ]
    let viewModel = LivePublicPlaylistViewModel(
      playlist: LiveLibraryFixtures.publicResult(url: listURL),
      service: service
    )

    await viewModel.reload()
    await viewModel.loadMore()
    await viewModel.toggleSaved()
    let createdSavedID = viewModel.savedID
    await viewModel.toggleSaved()

    XCTAssertEqual(
      viewModel.videos.map(\.id),
      ["video-1", "short", "second"]
    )
    XCTAssertNotNil(createdSavedID)
    XCTAssertNil(viewModel.savedID)
    XCTAssertEqual(
      service.actions.filter { $0.hasPrefix("public:") },
      ["public:first", "public:next"]
    )
  }
}
