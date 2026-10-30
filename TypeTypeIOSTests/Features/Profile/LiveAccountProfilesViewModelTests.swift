import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveAccountProfilesViewModelTests: XCTestCase {
  func testInstanceWithoutProfilesShowsUnavailableInsteadOfAnError() async {
    for status in [403, 404] {
      let viewModel = LiveAccountProfilesViewModel(service: StubProfileService(listError: NetworkError.statusCode(status, nil)))
      await viewModel.load()

      XCTAssertTrue(viewModel.isUnavailable)
      XCTAssertNil(viewModel.errorMessage)
    }
  }

  func testOtherFailuresStayErrors() async {
    let viewModel = LiveAccountProfilesViewModel(service: StubProfileService(listError: NetworkError.statusCode(500, nil)))
    await viewModel.load()

    XCTAssertFalse(viewModel.isUnavailable)
    XCTAssertNotNil(viewModel.errorMessage)
  }
}

private struct StubProfileService: LiveAccountProfileServiceProtocol {
  let listError: Error

  func list() async throws -> AccountProfilesResponse { throw listError }
  func create(name: String) async throws -> AccountProfileItem { throw listError }
  func rename(id: String, name: String) async throws -> AccountProfileItem { throw listError }
  func setDefault(id: String) async throws -> AccountProfileItem { throw listError }
  func switchTo(id: String) async throws -> ProfileSwitchResponse { throw listError }
  func delete(id: String) async throws { throw listError }
}
