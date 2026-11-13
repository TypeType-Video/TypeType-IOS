import AVFoundation

@MainActor
final class LiveCommentVoicePlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
  enum Phase: Equatable {
    case idle
    case loading
    case playing
    case paused
    case failed
  }

  @Published private(set) var activeID: String?
  @Published private(set) var phase = Phase.idle

  private let service: LiveCommentsServiceProtocol
  private var player: AVAudioPlayer?
  private var loading: Task<Void, Never>?

  init(service: LiveCommentsServiceProtocol) {
    self.service = service
  }

  func phase(for comment: LiveCommentItem) -> Phase {
    comment.id == activeID ? phase : .idle
  }

  func toggle(_ comment: LiveCommentItem) {
    guard let reply = comment.voiceReply, reply.canPlay else { return }
    if comment.id == activeID {
      switch phase {
      case .playing:
        player?.pause()
        phase = .paused
        return
      case .paused:
        player?.play()
        phase = .playing
        return
      case .loading:
        return
      case .idle, .failed:
        break
      }
    }
    stop()
    activeID = comment.id
    phase = .loading
    let id = comment.id
    loading = Task { [weak self] in await self?.load(reply.url, for: id) }
  }

  func stop() {
    loading?.cancel()
    loading = nil
    player?.stop()
    player = nil
    activeID = nil
    phase = .idle
  }

  private func load(_ url: String, for id: String) async {
    do {
      let data = try await service.voiceAudio(url: url)
      guard id == activeID, !Task.isCancelled else { return }
      let player = try AVAudioPlayer(data: data)
      player.delegate = self
      self.player = player
      phase = player.play() ? .playing : .failed
    } catch is CancellationError {
      return
    } catch {
      guard id == activeID else { return }
      AppLogger.playback.notice("voice reply failed: \(String(describing: error), privacy: .public)")
      player = nil
      phase = .failed
    }
  }

  nonisolated func audioPlayerDidFinishPlaying(_ finished: AVAudioPlayer, successfully flag: Bool) {
    let finishedID = ObjectIdentifier(finished)
    Task { @MainActor [weak self] in
      guard let self, let player, ObjectIdentifier(player) == finishedID else { return }
      stop()
    }
  }
}
