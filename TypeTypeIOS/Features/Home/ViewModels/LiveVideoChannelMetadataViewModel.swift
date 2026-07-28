import Combine
import Foundation

@MainActor
final class LiveVideoChannelMetadataViewModel: ObservableObject {
  @Published private(set) var subscriberCount: Int64?

  private let service: LiveChannelServiceProtocol
  private var requestID = UUID()

  init(service: LiveChannelServiceProtocol) {
    self.service = service
  }

  func load(
    channelURL: String,
    streamSubscriberCount: Int64?
  ) async {
    let currentRequest = UUID()
    requestID = currentRequest

    if let streamSubscriberCount,
      streamSubscriberCount >= 0 {
      subscriberCount = streamSubscriberCount
      return
    }

    subscriberCount = nil
    guard !channelURL.isEmpty else { return }

    do {
      let channel = try await service.channel(
        url: channelURL,
        nextPage: nil,
        sort: .latest
      )
      guard requestID == currentRequest, !Task.isCancelled else {
        return
      }
      subscriberCount = channel.subscriberCount >= 0
        ? channel.subscriberCount
        : nil
    } catch {
      guard requestID == currentRequest else { return }
      subscriberCount = nil
    }
  }
}
