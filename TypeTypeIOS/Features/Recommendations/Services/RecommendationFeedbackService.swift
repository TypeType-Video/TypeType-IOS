import Foundation

protocol RecommendationFeedbackServiceProtocol {
  func setEnabled(_ enabled: Bool)
  func sendEvent(
    type: RecommendationEventType,
    videoURL: String?,
    uploaderURL: String?,
    title: String?,
    watchRatio: Double?,
    watchDurationMs: Int64?
  ) async
  func sendFeedback(type: RecommendationFeedbackType, videoURL: String?, uploaderURL: String?) async
}

enum RecommendationEventType: String {
  case impression
  case click
  case watch
  case favorite
  case watchLaterAdd = "watch_later_add"
  case shortSkip = "short_skip"
}

enum RecommendationFeedbackType: String {
  case notInterested = "not_interested"
  case lessFromChannel = "less_from_channel"
}

private struct RecommendationEventRequest: Encodable {
  let eventType: String
  let serviceId: Int?
  let intent: String?
  let videoUrl: String?
  let uploaderUrl: String?
  let title: String?
  let watchRatio: Double?
  let watchDurationMs: Int64?
  let contextKey: String?
}

private struct RecommendationFeedbackRequest: Encodable {
  let feedbackType: String
  let videoUrl: String?
  let uploaderUrl: String?
}

actor RecommendationEventDeduper {
  private var sentEvents: Set<String> = []
  private var sentFeedback: Set<String> = []

  func shouldSendEvent(key: String) -> Bool {
    if sentEvents.contains(key) { return false }
    sentEvents.insert(key)
    return true
  }

  func shouldSendFeedback(key: String) -> Bool {
    if sentFeedback.contains(key) { return false }
    sentFeedback.insert(key)
    return true
  }
}

final class RecommendationFeedbackService: RecommendationFeedbackServiceProtocol {
  private let apiClient: APIClient
  private let deduper = RecommendationEventDeduper()
  private let lock = NSLock()
  private var enabled: Bool = true

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func setEnabled(_ enabled: Bool) {
    lock.lock()
    self.enabled = enabled
    lock.unlock()
  }

  private func isEnabled() -> Bool {
    lock.lock()
    let value = enabled
    lock.unlock()
    return value
  }

  func sendEvent(
    type: RecommendationEventType,
    videoURL: String?,
    uploaderURL: String?,
    title: String?,
    watchRatio: Double?,
    watchDurationMs: Int64?
  ) async {
    guard isEnabled() else { return }
    if type != .watch {
      let key = "\(type.rawValue):\(videoURL ?? "")"
      let shouldSend = await deduper.shouldSendEvent(key: key)
      guard shouldSend else { return }
    }

    guard let body = try? APIEndpoint.jsonBody(
      RecommendationEventRequest(
        eventType: type.rawValue,
        serviceId: 0,
        intent: "auto",
        videoUrl: videoURL,
        uploaderUrl: uploaderURL,
        title: title,
        watchRatio: watchRatio,
        watchDurationMs: watchDurationMs,
        contextKey: nil
      )
    ) else { return }

    let endpoint = APIEndpoint(
      path: "/recommendations/events",
      method: .post,
      headers: ["Content-Type": "application/json"],
      body: body,
      requiresAuth: true
    )
    do {
      try await apiClient.request(endpoint)
    } catch {
      return
    }
  }

  private func sendFeedback(type: String, videoURL: String?, uploaderURL: String?) async {
    guard isEnabled() else { return }
    let key = "\(type):\(videoURL ?? ""):\(uploaderURL ?? "")"
    let shouldSend = await deduper.shouldSendFeedback(key: key)
    guard shouldSend else { return }

    guard let body = try? APIEndpoint.jsonBody(
      RecommendationFeedbackRequest(
        feedbackType: type,
        videoUrl: videoURL,
        uploaderUrl: uploaderURL
      )
    ) else { return }

    let endpoint = APIEndpoint(
      path: "/recommendations/feedback",
      method: .post,
      headers: ["Content-Type": "application/json"],
      body: body,
      requiresAuth: true
    )
    do {
      try await apiClient.request(endpoint)
    } catch {
      return
    }
  }

  func sendFeedback(type: RecommendationFeedbackType, videoURL: String?, uploaderURL: String?) async {
    await sendFeedback(type: type.rawValue, videoURL: videoURL, uploaderURL: uploaderURL)
  }
}
