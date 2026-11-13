import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveDeviceLinkViewModelTests: XCTestCase {
  func testLooksUpTheCodeThenSignsTheDeviceIn() async {
    let service = FakeDeviceLinkService()
    let model = LiveDeviceLinkViewModel(service: service)
    model.code = " abcd-efgh "

    await model.lookUp()
    XCTAssertEqual(model.request, LiveDeviceLinkRequest(userCode: "ABCD-EFGH", deviceName: "Living room TV"))
    await model.approve()

    XCTAssertEqual(service.calls, ["lookup ABCD-EFGH", "approve ABCD-EFGH"])
    XCTAssertNil(model.request)
    XCTAssertEqual(model.outcome, .approved)
    XCTAssertNil(model.failure)
  }

  func testRefusingKeepsTheDeviceSignedOut() async {
    let service = FakeDeviceLinkService()
    let model = LiveDeviceLinkViewModel(service: service)
    model.code = "ABCD-EFGH"

    await model.lookUp()
    await model.deny()

    XCTAssertEqual(service.calls, ["lookup ABCD-EFGH", "deny ABCD-EFGH"])
    XCTAssertEqual(model.outcome, .denied)
  }

  func testAnUnknownCodeExplainsWhatToCheck() async {
    let service = FakeDeviceLinkService()
    service.failure = NetworkError.statusCode(404, "code_not_found")
    let model = LiveDeviceLinkViewModel(service: service)
    model.code = "WRONG"

    await model.lookUp()

    XCTAssertNil(model.request)
    XCTAssertEqual(
      model.failure,
      String(localized: "This code does not exist or has expired. Check the code on the other device.")
    )
  }

  func testEachRefusalHasItsOwnMessage() {
    let messages = [409, 429, 403, 500].map { LiveDeviceLinkViewModel.message(for: NetworkError.statusCode($0, nil)) }
    XCTAssertEqual(Set(messages).count, 4)
    XCTAssertNotEqual(LiveDeviceLinkViewModel.message(for: NetworkError.transport), messages[3])
  }

  func testCodesKeepOnlyLettersDigitsAndDashes() {
    XCTAssertEqual(LiveDeviceLinkRequest.normalized(" ab cd-ef\u{00E9}1 "), "ABCD-EF1")
    XCTAssertFalse(LiveDeviceLinkViewModel(service: FakeDeviceLinkService()).canLookUp)
  }
}

private final class FakeDeviceLinkService: LiveDeviceLinkServiceProtocol {
  var calls: [String] = []
  var failure: Error?

  func lookup(code: String) async throws -> LiveDeviceLinkRequest {
    let normalized = LiveDeviceLinkRequest.normalized(code)
    calls.append("lookup \(normalized)")
    if let failure { throw failure }
    return LiveDeviceLinkRequest(userCode: normalized, deviceName: "Living room TV")
  }

  func approve(code: String) async throws {
    calls.append("approve \(code)")
    if let failure { throw failure }
  }

  func deny(code: String) async throws {
    calls.append("deny \(code)")
    if let failure { throw failure }
  }
}
