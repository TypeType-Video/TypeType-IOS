import XCTest
@testable import TypeTypeIOS

final class LiveRecommenderModelTests: XCTestCase {
  func testDecodesNumbersAndFlagsAndRoundTripsTheSettings() throws {
    let json = #"{"enabled":true,"algorithmId":"signals","parameters":{"rows":8,"shuffle":true},"retentionDays":{"history":30}}"#
    let settings = try JSONDecoder().decode(LiveRecommenderSettings.self, from: Data(json.utf8))
    XCTAssertEqual(settings.parameters["rows"], .number(8))
    XCTAssertEqual(settings.parameters["shuffle"], .flag(true))
    XCTAssertEqual(settings.unusedData, [])
    let again = try JSONDecoder().decode(LiveRecommenderSettings.self, from: JSONEncoder().encode(settings))
    XCTAssertEqual(again, settings)
  }

  func testLabelsMatchTheWeb() {
    XCTAssertEqual(LiveAlgorithmLabels.retention(nil), "No limit")
    XCTAssertEqual(LiveAlgorithmLabels.retention(365), "1 year")
    XCTAssertEqual(LiveAlgorithmLabels.retention(180), "6 months")
    XCTAssertEqual(LiveAlgorithmLabels.retention(30), "30 d")
    XCTAssertEqual(LiveAlgorithmLabels.dropped("seen", count: 4), "4 already watched")
    XCTAssertEqual(LiveAlgorithmParametersView.format(0.35, unit: "%").filter(\.isNumber), "35")
    XCTAssertEqual(LiveAlgorithmParametersView.format(20, unit: nil), "20")
  }
}

@MainActor
final class LiveAlgorithmViewModelTests: XCTestCase {
  func testChangesShowAtOnceAndOnlyTheLastOneIsSaved() async throws {
    let service = RecommenderStub()
    let model = LiveAlgorithmViewModel(service: service, feedback: nil, delay: .milliseconds(50))
    await model.load()
    XCTAssertEqual(model.current?.id, "b")

    let parameter = try XCTUnwrap(model.current?.parameters.first)
    model.setValue(.number(5), for: parameter.id)
    model.setValue(.number(6), for: parameter.id)
    model.toggleUse("history")
    XCTAssertEqual(model.value(parameter), .number(6))
    try await Task.sleep(for: .milliseconds(300))
    XCTAssertEqual(service.saved.count, 1)
    XCTAssertEqual(service.saved.last?.parameters[parameter.id], .number(6))
    XCTAssertEqual(service.saved.last?.unusedData, ["history"])

    model.select("a")
    try await Task.sleep(for: .milliseconds(30))
    XCTAssertEqual(service.saved.last?.algorithmID, "a")
    XCTAssertEqual(service.saved.last?.parameters, [:])
  }
}

private final class RecommenderStub: LiveRecommenderServiceProtocol, @unchecked Sendable {
  var saved: [LiveRecommenderSettings] = []

  func algorithms() async throws -> LiveRecommenderAlgorithms {
    let json = #"{"default_algorithm":"b","algorithms":[{"id":"a","name":"A","description":"","parameters":[]},{"id":"b","name":"B","description":"","parameters":[{"id":"rows","group":"rows","label":"Rows","type":"number","min":1,"max":10,"step":1,"default":4}]}]}"#
    return try JSONDecoder().decode(LiveRecommenderAlgorithms.self, from: Data(json.utf8))
  }

  func settings() async throws -> LiveRecommenderSettings { LiveRecommenderSettings() }

  func save(_ settings: LiveRecommenderSettings) async throws -> LiveRecommenderSettings {
    saved.append(settings)
    return settings
  }

  func data() async throws -> [LiveRecommenderDataCategory] { [] }
  func lastHome() async throws -> LiveRecommenderTrace? { nil }
  func opinions() async throws -> [LiveRecommenderOpinion] { [] }
}
