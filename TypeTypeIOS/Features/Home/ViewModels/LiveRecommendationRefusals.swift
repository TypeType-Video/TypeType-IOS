import Foundation

@MainActor
final class LiveRecommendationRefusals: ObservableObject {
  enum State: Equatable {
    case sending
    case saved(id: String)
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
      let id = try await service.refuse(video)
      states[key] = .saved(id: id)
      return nil
    } catch {
      states[key] = nil
      return Self.message(for: error)
    }
  }

  func undo(_ video: LiveVideoItem) async -> String? {
    let key = video.canonicalID
    guard let service, case let .saved(id) = states[key] else { return nil }
    states[key] = .withdrawing(id: id)
    do {
      try await service.withdraw(id: id)
      states[key] = nil
      return nil
    } catch {
      states[key] = .saved(id: id)
      return Self.message(for: error)
    }
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The action could not be completed."
  }
}
