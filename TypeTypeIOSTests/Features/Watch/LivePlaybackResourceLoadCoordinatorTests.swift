import Foundation
import XCTest
@testable import TypeTypeIOS

final class LivePlaybackResourceLoadCoordinatorTests: XCTestCase {
  func testCoalescesConcurrentLoadsForTheSameResource() async throws {
    let coordinator = LivePlaybackResourceLoadCoordinator()
    let counter = ResourceLoadCounter()

    let resources = try await withThrowingTaskGroup(
      of: LivePlaybackHTTPServer.Resource.self,
      returning: [LivePlaybackHTTPServer.Resource].self
    ) { group in
      for _ in 0..<20 {
        group.addTask {
          try await coordinator.value(for: "shared") {
            try await counter.load()
          }
        }
      }
      var values: [LivePlaybackHTTPServer.Resource] = []
      for try await resource in group {
        values.append(resource)
      }
      return values
    }

    let callCount = await counter.callCount
    XCTAssertEqual(callCount, 1)
    XCTAssertEqual(resources.count, 20)
    XCTAssertTrue(resources.allSatisfy {
      $0.data == Data("media".utf8)
    })
    let activeLoadCount = coordinator.activeLoadCount
    XCTAssertEqual(activeLoadCount, 0)
  }

  func testStartsANewLoadAfterThePreviousLoadCompletes() async throws {
    let coordinator = LivePlaybackResourceLoadCoordinator()
    let counter = ResourceLoadCounter()

    _ = try await coordinator.value(for: "shared") {
      try await counter.load()
    }
    _ = try await coordinator.value(for: "shared") {
      try await counter.load()
    }

    let callCount = await counter.callCount
    XCTAssertEqual(callCount, 2)
  }

  func testCancelAllImmediatelyStopsOutstandingLoads() async {
    let coordinator = LivePlaybackResourceLoadCoordinator()
    let load = Task {
      try await coordinator.value(for: "slow") {
        try await Task.sleep(for: .seconds(60))
        return LivePlaybackHTTPServer.Resource(
          data: Data(),
          mimeType: "video/mp4"
        )
      }
    }
    for _ in 0..<100 where coordinator.activeLoadCount == 0 {
      await Task.yield()
    }
    XCTAssertEqual(coordinator.activeLoadCount, 1)

    coordinator.cancelAll()

    do {
      _ = try await load.value
      XCTFail("The outstanding load should have been cancelled.")
    } catch is CancellationError {
      XCTAssertEqual(coordinator.activeLoadCount, 0)
    } catch {
      XCTFail("Unexpected cancellation error: \(error)")
    }
  }

  func testDynamicProviderPlaylistsAreNotCacheable() {
    XCTAssertTrue(
      LivePlaybackHTTPServer.isDynamicPlaylistURL(
        URL(string: "https://example.test/live/master.m3u8")!
      )
    )
    XCTAssertTrue(
      LivePlaybackHTTPServer.isDynamicPlaylistURL(
        URL(string: "https://example.test/api?format=hls")!
      )
    )
    XCTAssertFalse(
      LivePlaybackHTTPServer.isDynamicPlaylistURL(
        URL(string: "https://example.test/segment/42.m4s")!
      )
    )
  }
}

private actor ResourceLoadCounter {
  private(set) var callCount = 0

  func load() async throws -> LivePlaybackHTTPServer.Resource {
    callCount += 1
    try await Task.sleep(for: .milliseconds(100))
    return LivePlaybackHTTPServer.Resource(
      data: Data("media".utf8),
      mimeType: "video/mp4"
    )
  }
}
