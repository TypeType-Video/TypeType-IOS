import XCTest

@testable import TypeTypeIOS

@MainActor
final class LiveSettingsViewModelTests: XCTestCase {
  func testChangeIsSavedWithoutAButton() async throws {
    let service = SettingsServiceSpy()
    var applied: [LiveSettings] = []
    let viewModel = makeViewModel(service: service) { applied.append($0) }
    await viewModel.prepare()

    viewModel.draft.hideShorts = true

    try await waitUntil { service.updates.count == 1 }
    XCTAssertEqual(service.updates.first?.hideShorts, true)
    XCTAssertEqual(applied.last?.hideShorts, true)
    XCTAssertNil(viewModel.errorMessage)
  }

  func testQuickChangesSendOnlyTheLastValue() async throws {
    let service = SettingsServiceSpy()
    let viewModel = makeViewModel(service: service, saveDelay: .milliseconds(80))
    await viewModel.prepare()

    viewModel.draft.sponsorBlockMinimumDuration = 1
    viewModel.draft.sponsorBlockMinimumDuration = 2
    viewModel.draft.sponsorBlockMinimumDuration = 3

    try await waitUntil { service.updates.count == 1 }
    try await Task.sleep(for: .milliseconds(200))
    XCTAssertEqual(service.updates.map(\.sponsorBlockMinimumDuration), [3])
  }

  func testRefusedChangeGoesBackAndSaysSo() async throws {
    let service = SettingsServiceSpy()
    service.failsUpdates = true
    let viewModel = makeViewModel(service: service)
    await viewModel.prepare()

    viewModel.draft.hideShorts = true

    try await waitUntil { viewModel.errorMessage != nil }
    XCTAssertFalse(viewModel.draft.hideShorts)
    XCTAssertEqual(service.updates.count, 1)
  }

  func testLoadingDoesNotSave() async throws {
    let service = SettingsServiceSpy()
    service.stored.hideShorts = true
    let viewModel = makeViewModel(service: service)

    await viewModel.prepare()
    try await Task.sleep(for: .milliseconds(100))

    XCTAssertTrue(viewModel.draft.hideShorts)
    XCTAssertTrue(service.updates.isEmpty)
  }

  private func makeViewModel(
    service: SettingsServiceSpy,
    saveDelay: Duration = .milliseconds(10),
    onSaved: @escaping @MainActor (LiveSettings) -> Void = { _ in }
  ) -> LiveSettingsViewModel {
    LiveSettingsViewModel(
      service: service,
      serviceSelection: LiveServiceSelection(
        settingsService: service,
        defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard
      ),
      deArrowStore: LiveDeArrowStore(
        service: DeArrowServiceStub(),
        settingsService: service
      ),
      saveDelay: saveDelay,
      onSaved: onSaved
    )
  }

  private func waitUntil(
    _ condition: @MainActor () -> Bool,
    file: StaticString = #filePath,
    line: UInt = #line
  ) async throws {
    for _ in 0..<100 where !condition() {
      try await Task.sleep(for: .milliseconds(10))
    }
    XCTAssertTrue(condition(), file: file, line: line)
  }
}

@MainActor
private final class SettingsServiceSpy: LiveSettingsServiceProtocol {
  var stored = LiveSettings()
  var failsUpdates = false
  private(set) var updates: [LiveSettings] = []

  func settings() async throws -> LiveSettings {
    stored
  }

  func update(_ settings: LiveSettings) async throws -> LiveSettings {
    updates.append(settings)
    if failsUpdates {
      throw URLError(.notConnectedToInternet)
    }
    stored = settings
    return settings
  }
}

private struct DeArrowServiceStub: LiveDeArrowServiceProtocol {
  func item(videoID: String) async throws -> LiveDeArrowItem {
    throw URLError(.unsupportedURL)
  }

  func absoluteURL(_ value: String?) -> URL? { nil }

  func thumbnailURL(videoID: String, time: Double) -> URL? { nil }
}
