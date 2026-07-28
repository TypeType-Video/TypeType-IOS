import Foundation
@testable import TypeTypeIOS

struct AcceptingMediaValidator: LiveOfflineMediaValidating {
  func validate(fileURL: URL, mode: String) async throws {}
}

final class DownloadServiceStub: LiveDownloaderServiceProtocol {
  private let lock = NSLock()
  private var failuresRemaining: Int
  private var artifactRequestCount = 0
  private var requestedOptions: [LiveDownloadOptions] = []
  private let artifactDelay: Duration

  init(
    artifactFailuresRemaining: Int = 0,
    artifactDelay: Duration = .zero
  ) {
    failuresRemaining = artifactFailuresRemaining
    self.artifactDelay = artifactDelay
  }

  var artifactAttempts: Int {
    lock.withLock { artifactRequestCount }
  }

  var createdOptions: [LiveDownloadOptions] {
    lock.withLock { requestedOptions }
  }

  func create(
    videoURL: String,
    options: LiveDownloadOptions
  ) async throws -> LiveDownloadJob {
    lock.withLock {
      requestedOptions.append(options)
    }
    return Self.job(status: "queued", stage: "queued")
  }

  func job(id: String) async throws -> LiveDownloadJob {
    Self.job(status: "done", stage: "done")
  }

  func cancel(id: String) async throws -> LiveDownloadJob {
    Self.job(status: "cancelled", stage: "cancelled")
  }

  func delete(id: String) async throws {}

  func artifact(id: String) async throws -> URL {
    if artifactDelay > .zero {
      try await Task.sleep(for: artifactDelay)
    }
    let shouldFail = lock.withLock {
      artifactRequestCount += 1
      guard failuresRemaining > 0 else { return false }
      failuresRemaining -= 1
      return true
    }
    if shouldFail {
      throw NetworkError.transport
    }
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try Data("offline-media".utf8).write(to: url, options: .atomic)
    return url
  }

  private static func job(
    status: String,
    stage: String
  ) -> LiveDownloadJob {
    LiveDownloadJob(
      id: "job-1",
      url: "https://www.youtube.com/watch?v=mcV4qoX2MIE",
      status: status,
      title: "Download test",
      resolved: LiveResolvedDownload(
        videoItag: "137",
        audioItag: "140",
        height: 1080,
        fps: 30,
        videoCodec: "avc1",
        audioCodec: "mp4a",
        container: "mp4",
        bitrate: nil,
        fileName: "Download test.mp4"
      ),
      progressPercent: status == "done" ? 100 : 0,
      downloadedBytes: status == "done" ? 13 : 0,
      totalBytes: 13,
      speedBytesPerSecond: nil,
      etaSeconds: nil,
      stage: stage,
      queuedAt: nil,
      startedAt: nil,
      finishedAt: nil,
      queueWaitMilliseconds: nil,
      runTimeMilliseconds: nil,
      errorCode: nil,
      error: nil
    )
  }
}
