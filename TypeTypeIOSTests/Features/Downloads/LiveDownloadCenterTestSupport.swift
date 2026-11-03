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
  private let artifactProgress: Double?
  private var interruptionsRemaining: Int
  private var receivedResumeData: [Data?] = []
  private var jobFailuresRemaining: Int
  private var jobRequestCount = 0
  private let jobError: NetworkError

  init(
    jobFailuresRemaining: Int = 0,
    jobError: NetworkError = .statusCode(503, nil),
    artifactFailuresRemaining: Int = 0,
    artifactDelay: Duration = .zero,
    artifactProgress: Double? = nil,
    artifactInterruptions: Int = 0
  ) {
    self.artifactProgress = artifactProgress
    interruptionsRemaining = artifactInterruptions
    self.jobFailuresRemaining = jobFailuresRemaining
    self.jobError = jobError
    failuresRemaining = artifactFailuresRemaining
    self.artifactDelay = artifactDelay
  }

  var jobAttempts: Int {
    lock.withLock { jobRequestCount }
  }

  var artifactAttempts: Int {
    lock.withLock { artifactRequestCount }
  }

  var artifactResumeData: [Data?] {
    lock.withLock { receivedResumeData }
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
    let shouldFail = lock.withLock {
      jobRequestCount += 1
      guard jobFailuresRemaining > 0 else { return false }
      jobFailuresRemaining -= 1
      return true
    }
    if shouldFail {
      throw jobError
    }
    return Self.job(status: "done", stage: "done")
  }

  func cancel(id: String) async throws -> LiveDownloadJob {
    Self.job(status: "cancelled", stage: "cancelled")
  }

  func delete(id: String) async throws {}

  func artifact(
    id: String,
    resumeData: Data?,
    progress: @escaping @Sendable (DownloadProgress) -> Void
  ) async throws -> URL {
    let interrupted = lock.withLock {
      receivedResumeData.append(resumeData)
      guard interruptionsRemaining > 0 else { return false }
      interruptionsRemaining -= 1
      return true
    }
    if interrupted {
      progress(DownloadProgress(receivedBytes: 70, expectedBytes: 1_000))
      throw DownloadInterruption(resumeData: Data("partial".utf8))
    }
    if let artifactProgress {
      progress(DownloadProgress(receivedBytes: Int64(artifactProgress * 1_000), expectedBytes: 1_000))
    }
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
