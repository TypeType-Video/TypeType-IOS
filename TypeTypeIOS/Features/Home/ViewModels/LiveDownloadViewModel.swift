import Combine
import Foundation

@MainActor
final class LiveDownloadViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case creating
    case tracking
    case done
    case failed(String)
  }

  @Published var mode = LiveDownloadMode.video {
    didSet {
      applyModeDefaults()
      adoptExistingRecord()
    }
  }
  @Published var quality = "1080p"
  @Published var format = "mp4"
  @Published var sponsorBlock = false
  @Published var includesSubtitles = false
  @Published var subtitleLanguage = "en"
  @Published private(set) var state = State.idle
  @Published private(set) var job: LiveDownloadJob?
  @Published private(set) var isCancelling = false
  @Published private(set) var isClearing = false

  let video: LiveVideoItem
  private let center: LiveDownloadCenter
  private var recordID: String?
  private var recordsObservation: AnyCancellable?

  init(
    video: LiveVideoItem,
    center: LiveDownloadCenter
  ) {
    self.video = video
    self.center = center
    adoptExistingRecord()
    recordsObservation = center.$records.sink { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.synchronize()
      }
    }
  }

  var canStart: Bool {
    state == .idle || isTerminal
  }

  var isWorking: Bool {
    state == .creating || state == .tracking
  }

  var isTerminal: Bool {
    switch state {
    case .done, .failed:
      return true
    default:
      return false
    }
  }

  var progress: Double? {
    guard let value = job?.progressPercent else { return nil }
    return Double(min(max(value, 0), 100)) / 100
  }

  func start() async {
    guard canStart else { return }
    state = .creating
    do {
      if let recordID,
        center.record(id: recordID)?.state.canRetry == true {
        try await center.retry(
          id: recordID,
          options: options
        )
      } else {
        let record = try await center.start(
          video: video,
          options: options
        )
        recordID = record.id
      }
      synchronize()
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  func cancel() async {
    guard let recordID, isWorking, !isCancelling else { return }
    isCancelling = true
    defer { isCancelling = false }
    do {
      try await center.cancel(id: recordID)
      synchronize()
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  func clear() async {
    guard let recordID, !isClearing else {
      reset()
      return
    }
    isClearing = true
    defer { isClearing = false }
    do {
      try await center.remove(id: recordID)
      reset()
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  var artifactURL: URL? {
    guard let recordID, let record = center.record(id: recordID) else {
      return nil
    }
    return center.artifactURL(for: record)
  }

  private func synchronize() {
    guard let recordID, let record = center.record(id: recordID) else {
      return
    }
    job = record.job
    switch record.state {
    case .ready:
      state = .done
    case .failed:
      state = .failed(
        record.failureMessage?
          .trimmingCharacters(in: .whitespacesAndNewlines)
          .nilIfEmpty
          ?? "The download failed."
      )
    case .cancelled:
      state = .failed("The download was cancelled.")
    case .queued, .preparing, .downloading, .finalizing, .saving:
      state = .tracking
    }
  }

  private func adoptExistingRecord() {
    recordID = center.existingRecord(
      forVideoURL: video.url,
      mode: mode.rawValue
    ).map(\.id)

    if recordID != nil {
      synchronize()
    } else {
      reset()
    }
  }

  private func reset() {
    recordID = nil
    job = nil
    state = .idle
  }

  private func applyModeDefaults() {
    switch mode {
    case .video:
      format = "mp4"
      quality = "1080p"
    case .audio:
      format = "m4a"
      quality = "best"
    case .thumbnail:
      format = "jpg"
      quality = "best"
      includesSubtitles = false
      sponsorBlock = false
    }
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The download service is unavailable."
  }

}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
