import Foundation

@MainActor
final class LiveChatFeed: ObservableObject {
  static let publishInterval: Duration = .milliseconds(400)

  @Published private(set) var buffer = LiveChatBuffer()

  private let service: LiveChatService?
  private let videoURL: String
  private var pending: [LiveChatEvent] = []
  private var reader: Task<Void, Never>?
  private var publisher: Task<Void, Never>?

  init(videoURL: String, service: LiveChatService?) {
    self.videoURL = videoURL
    self.service = service
  }

  func start() {
    guard reader == nil, let service else { return }
    let url = videoURL
    reader = Task { [weak self] in
      for await event in service.events(videoURL: url) {
        guard let self else { return }
        pending.append(event)
      }
      self?.publish()
    }
    publisher = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: Self.publishInterval)
        self?.publish()
      }
    }
  }

  func stop() {
    reader?.cancel()
    publisher?.cancel()
    reader = nil
    publisher = nil
    publish()
  }

  private func publish() {
    guard !pending.isEmpty else { return }
    var next = buffer
    next.apply(pending)
    pending.removeAll()
    buffer = next
  }
}
