import XCTest
@testable import TypeTypeIOS

final class LiveFocusSettingsTests: XCTestCase {
  func testStatusCountsTheDayAndTheHoursLeftLikeTheWeb() throws {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let started = Int64(now.timeIntervalSince1970 * 1000) - 2 * 86_400_000 - 1
    let on = try settings(#""enabled":true,"startedAt":\#(started),"disableAt":null,"entertainmentShare":0.736"#)
    let leaving = try settings(#""enabled":true,"startedAt":1,"disableAt":\#(Int64(now.timeIntervalSince1970 * 1000) + 5_400_000),"entertainmentShare":1"#)
    let off = try settings(#""enabled":false,"startedAt":null,"disableAt":null,"entertainmentShare":1"#)

    XCTAssertEqual(on.status(now: now), .on(day: 3, total: 60, percent: 74))
    XCTAssertEqual(leaving.status(now: now), .leaving(hours: 2))
    XCTAssertEqual(off.status(now: now), .off)
    XCTAssertEqual(LiveFocusSettings.choices([30, 60, 90], current: 45), [30, 45, 60, 90])
  }

  func testRequestsOnlySendWhatChanges() throws {
    let data = try JSONEncoder().encode(LiveFocusRequest(enabled: false, studyGroupID: ""))
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    XCTAssertEqual(json.count, 2)
    XCTAssertEqual(json["studyGroupId"] as? String, "")
  }

  private func settings(_ fields: String) throws -> LiveFocusSettings {
    let json = #"{"entertainmentGroupId":"g","studyGroupId":null,"schedule":"weekdays","timezone":"Europe/Paris","transitionDays":60,"archiveDays":7,"# + fields + "}"
    return try JSONDecoder().decode(LiveFocusSettings.self, from: Data(json.utf8))
  }
}

@MainActor
final class LiveFocusViewModelTests: XCTestCase {
  func testLockedSettingsCannotChangeAndTheScheduleSendsTheTimezone() async {
    let service = FocusService()
    let model = LiveFocusViewModel(service: service, subscriptions: GroupsStub()) { "Europe/Paris" }
    await model.load()
    await model.setSchedule(.weekdays)
    XCTAssertEqual(service.requests.last, LiveFocusRequest(enabled: false, schedule: .weekdays, timezone: "Europe/Paris"))

    await model.turnOn()
    await model.setArchive(14)
    XCTAssertEqual(service.requests.count, 2)
  }
}

private final class FocusService: LiveFocusServiceProtocol, @unchecked Sendable {
  var requests: [LiveFocusRequest] = []
  private var enabled = false

  func settings() async throws -> LiveFocusSettings { try make() }

  func save(_ request: LiveFocusRequest) async throws -> LiveFocusSettings {
    requests.append(request)
    enabled = request.enabled
    return try make()
  }

  private func make() throws -> LiveFocusSettings {
    let json = #"{"enabled":\#(enabled),"entertainmentGroupId":"g","studyGroupId":null,"schedule":"always","timezone":null,"transitionDays":60,"archiveDays":7,"startedAt":null,"disableAt":null,"entertainmentShare":1}"#
    return try JSONDecoder().decode(LiveFocusSettings.self, from: Data(json.utf8))
  }
}

private struct GroupsStub: LiveSubscriptionsServiceProtocol {
  func subscriptions() async throws -> [LiveSubscription] { [] }
  func subscribe(channelURL: String, name: String, avatarURL: String) async throws -> LiveSubscription { throw CancellationError() }
  func unsubscribe(channelURL: String) async throws {}
}
