import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveCollectionViewModelTests: XCTestCase {
  func testFavoritesLoadSortAndRemove() async {
    let service = LiveLibraryServiceStub()
    service.favoriteItems = [
      LiveLibraryFixtures.favorite(
        url: "https://video.test/z",
        title: "Zulu",
        savedAt: 10
      ),
      LiveLibraryFixtures.favorite(
        url: "https://video.test/a",
        title: "Alpha",
        savedAt: 20
      ),
    ]
    let viewModel = LiveCollectionViewModel(
      kind: .favorites,
      service: service
    )

    await viewModel.reload()
    XCTAssertEqual(viewModel.displayedVideos.map(\.title), ["Alpha", "Zulu"])

    viewModel.sort = .title
    XCTAssertEqual(viewModel.displayedVideos.map(\.title), ["Alpha", "Zulu"])

    await viewModel.remove(viewModel.displayedVideos[0])
    XCTAssertEqual(viewModel.videos.map(\.title), ["Zulu"])
    XCTAssertEqual(service.actions.count, 1)
  }

  func testWatchLaterLoadsFromDedicatedCollection() async {
    let service = LiveLibraryServiceStub()
    service.watchLaterItems = [LiveLibraryFixtures.watchLater()]
    let viewModel = LiveCollectionViewModel(
      kind: .watchLater,
      service: service
    )

    await viewModel.prepare()

    XCTAssertEqual(viewModel.state, .loaded)
    XCTAssertEqual(viewModel.videos.first?.title, "Watch later")
  }
}
