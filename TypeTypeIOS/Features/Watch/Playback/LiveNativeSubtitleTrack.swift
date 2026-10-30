import Foundation

@MainActor
final class LiveNativeSubtitleTrack: ObservableObject {
  @Published private(set) var cues: [LiveSubtitleCue] = []
  @Published private(set) var failureID: UUID?
  private var loadedID: String?
  private var task: Task<Void, Never>?

  func load(_ subtitle: LivePlaybackSubtitle, using service: LivePlaybackServiceProtocol) {
    guard loadedID != subtitle.id else { return }
    clear()
    loadedID = subtitle.id
    task = Task { [weak self] in
      do {
        let data = try await service.subtitleData(for: subtitle)
        let cues = await Task.detached(priority: .utility) {
          LiveSubtitleDocument.cues(in: data, mimeType: subtitle.mimeType)
        }.value
        guard !Task.isCancelled else { return }
        if cues.isEmpty {
          self?.fail(subtitle, reason: "no readable cue in \(data.count) bytes")
        } else {
          self?.cues = cues
        }
      } catch {
        guard !Task.isCancelled, !(error is CancellationError) else { return }
        self?.fail(subtitle, reason: String(describing: error))
      }
    }
  }

  func clear() {
    task?.cancel()
    task = nil
    loadedID = nil
    if !cues.isEmpty { cues = [] }
  }

  private func fail(_ subtitle: LivePlaybackSubtitle, reason: String) {
    AppLogger.playback.error(
      "subtitles \(subtitle.languageTag, privacy: .public) failed: \(reason, privacy: .public)"
    )
    failureID = UUID()
  }
}
