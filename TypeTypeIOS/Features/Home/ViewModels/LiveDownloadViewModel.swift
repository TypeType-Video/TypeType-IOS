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
    didSet { applyModeDefaults() }
  }
  @Published var quality = "balanced"
  @Published var format = "mp4"
  @Published var sponsorBlock = false
  @Published var includesSubtitles = false
  @Published var subtitleLanguage = "en"
  @Published private(set) var state = State.idle
  @Published private(set) var job: LiveDownloadJob?
  @Published private(set) var isCancelling = false
  @Published private(set) var isClearing = false

  let video: LiveVideoItem
  private let service: LiveDownloaderServiceProtocol
  private var trackingTask: Task<Void, Never>?

  init(
    video: LiveVideoItem,
    service: LiveDownloaderServiceProtocol
  ) {
    self.video = video
    self.service = service
  }

  deinit {
    trackingTask?.cancel()
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
    trackingTask?.cancel()
    job = nil
    state = .creating
    do {
      let created = try await service.create(
        videoURL: video.url,
        options: options
      )
      job = created
      updateState(from: created)
      guard created.status == "queued"
        || created.status == "running"
      else {
        return
      }
      track(id: created.id)
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  func cancel() async {
    guard let job, isWorking, !isCancelling else { return }
    isCancelling = true
    defer { isCancelling = false }
    do {
      let updated = try await service.cancel(id: job.id)
      self.job = updated
      updateState(from: updated)
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  func clear() async {
    guard let job, !isClearing else {
      reset()
      return
    }
    isClearing = true
    defer { isClearing = false }
    do {
      try await service.delete(id: job.id)
      reset()
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  func artifactURL(baseURL: URL?) -> URL? {
    guard let baseURL, let id = job?.id,
      var components = URLComponents(
        url: baseURL,
        resolvingAgainstBaseURL: false
      )
    else {
      return nil
    }
    let basePath = components.path.hasSuffix("/")
      ? String(components.path.dropLast())
      : components.path
    components.path =
      "\(basePath)/downloader/jobs/\(id)/artifact"
    components.queryItems = nil
    components.fragment = nil
    return components.url
  }

  private var options: LiveDownloadOptions {
    LiveDownloadOptions(
      mode: mode.rawValue,
      quality: quality,
      format: format,
      allowQualityFallback: true,
      sponsorBlock: sponsorBlock,
      sponsorBlockCategories: ["sponsor", "intro"],
      thumbnailOnly: mode == .thumbnail,
      subtitles: LiveDownloadSubtitleOptions(
        enabled: includesSubtitles,
        auto: includesSubtitles,
        embed: includesSubtitles && mode == .video,
        languages: subtitleLanguage.isEmpty
          ? []
          : [subtitleLanguage],
        format: "srt"
      )
    )
  }

  private func track(id: String) {
    trackingTask?.cancel()
    trackingTask = Task {
      while !Task.isCancelled {
        do {
          try await Task.sleep(for: .seconds(1))
          let updated = try await service.job(id: id)
          try Task.checkCancellation()
          job = updated
          updateState(from: updated)
          guard updated.status == "queued"
            || updated.status == "running"
          else {
            return
          }
        } catch is CancellationError {
          return
        } catch {
          state = .failed(Self.message(for: error))
          return
        }
      }
    }
  }

  private func updateState(from job: LiveDownloadJob) {
    switch job.status {
    case "done":
      state = .done
    case "failed":
      state = .failed(
        job.error?.trimmingCharacters(in: .whitespacesAndNewlines)
          .nilIfEmpty
          ?? "The download failed."
      )
    default:
      state = .tracking
    }
  }

  private func reset() {
    trackingTask?.cancel()
    job = nil
    state = .idle
  }

  private func applyModeDefaults() {
    switch mode {
    case .video:
      format = "mp4"
      quality = "balanced"
    case .audio:
      format = "mp3"
      quality = "balanced"
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
