import Foundation

@MainActor
final class LiveRecommendationRefusals: ObservableObject {
  enum State: Equatable {
    case sending
    case saved(id: String, reason: LiveRefusalReason?)
    case withdrawing(id: String)
  }

  @Published private(set) var states: [String: State] = [:]

  private let service: LiveRecommenderFeedbackServiceProtocol?

  init(service: LiveRecommenderFeedbackServiceProtocol?) {
    self.service = service
  }

  var isAvailable: Bool {
    service != nil
  }

  func state(for video: LiveVideoItem) -> State? {
    states[video.canonicalID]
  }

  func refuse(_ video: LiveVideoItem) async -> String? {
    let key = video.canonicalID
    guard let service, states[key] == nil else { return nil }
    states[key] = .sending
    do {
      let id = try await service.refuse(video, reason: nil)
      states[key] = .saved(id: id, reason: nil)
      return nil
    } catch {
      states[key] = nil
      return Self.message(for: error)
    }
  }

  // The server keeps one opinion per video: sending it again with a reason only adds the reason.
  func explain(_ video: LiveVideoItem, reason: LiveRefusalReason) async -> String? {
    let key = video.canonicalID
    guard let service, case let .saved(id, nil) = states[key] else { return nil }
    states[key] = .saved(id: id, reason: reason)
    do {
      _ = try await service.refuse(video, reason: reason)
      return nil
    } catch {
      if states[key] == .saved(id: id, reason: reason) {
        states[key] = .saved(id: id, reason: nil)
      }
      return Self.message(for: error)
    }
  }

  func undo(_ video: LiveVideoItem) async -> String? {
    let key = video.canonicalID
    guard let service, case let .saved(id, reason) = states[key] else { return nil }
    states[key] = .withdrawing(id: id)
    do {
      try await service.withdraw(id: id)
      states[key] = nil
      return nil
    } catch {
      states[key] = .saved(id: id, reason: reason)
      return Self.message(for: error)
    }
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The action could not be completed."
  }
}
