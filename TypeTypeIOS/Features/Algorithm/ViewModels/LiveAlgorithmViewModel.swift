import Foundation

@MainActor
final class LiveAlgorithmViewModel: ObservableObject {
  static let saveDelay: Duration = .milliseconds(700)

  @Published private(set) var algorithms: [LiveRecommenderAlgorithm] = []
  @Published private(set) var settings = LiveRecommenderSettings()
  @Published private(set) var loaded = false
  @Published private(set) var error: String?
  @Published private(set) var categories: [LiveRecommenderDataCategory] = []
  @Published private(set) var trace: LiveRecommenderTrace?
  @Published private(set) var traceLoaded = false
  @Published private(set) var opinions: [LiveRecommenderOpinion] = []

  private let service: LiveRecommenderServiceProtocol
  private let feedback: LiveRecommenderFeedbackServiceProtocol?
  private let delay: Duration
  private var defaultID: String?
  private var pending: Task<Void, Never>?

  init(service: LiveRecommenderServiceProtocol, feedback: LiveRecommenderFeedbackServiceProtocol?, delay: Duration = saveDelay) {
    self.service = service
    self.feedback = feedback
    self.delay = delay
  }

  var current: LiveRecommenderAlgorithm? {
    algorithms.first { $0.id == (settings.algorithmID ?? defaultID) } ?? algorithms.first
  }

  func load() async {
    do {
      async let list = service.algorithms()
      async let stored = service.settings()
      let (answer, values) = try await (list, stored)
      algorithms = answer.algorithms
      defaultID = answer.defaultAlgorithm
      settings = values
      loaded = true
      error = nil
    } catch {
      self.error = LiveUserError(error).message ?? String(localized: "The algorithm could not be loaded.")
    }
  }

  func name(of id: String) -> String { algorithms.first { $0.id == id }?.name ?? id }

  func value(_ parameter: LiveRecommenderParameter) -> LiveRecommenderValue {
    settings.parameters[parameter.id] ?? parameter.defaultValue
  }

  func setEnabled(_ enabled: Bool) { change(now: true) { $0.enabled = enabled } }

  func select(_ id: String) {
    change(now: true) {
      $0.algorithmID = id
      $0.parameters = [:]
    }
  }

  func setValue(_ value: LiveRecommenderValue, for id: String) { change { $0.parameters[id] = value } }
  func resetValues() { change(now: true) { $0.parameters = [:] } }
  func toggleUse(_ category: String) { change { $0.unusedData.toggle(category) } }
  func toggleExcluded(_ item: String) { change { $0.excludedItems.toggle(item) } }

  func setRetention(_ days: Int?, for category: String) {
    change { $0.retentionDays[category] = days }
  }

  func uses(_ category: LiveRecommenderDataCategory) -> Bool { !settings.unusedData.contains(category.id) }
  func excludes(_ item: LiveRecommenderDataItem) -> Bool { settings.excludedItems.contains(item.id) }
  func retention(_ category: LiveRecommenderDataCategory) -> Int? { settings.retentionDays[category.id] }

  func loadData() async {
    if let answer = try? await service.data() { categories = answer }
  }

  func loadTrace() async {
    trace = try? await service.lastHome()
    traceLoaded = true
  }

  func loadOpinions() async {
    if let answer = try? await service.opinions() { opinions = answer }
  }

  func remove(_ opinion: LiveRecommenderOpinion) async {
    guard let feedback else { return }
    do {
      try await feedback.withdraw(id: opinion.id)
      opinions.removeAll { $0.id == opinion.id }
    } catch {
      self.error = LiveUserError(error).message ?? String(localized: "The change could not be saved.")
    }
  }

  private func change(now: Bool = false, _ edit: (inout LiveRecommenderSettings) -> Void) {
    edit(&settings)
    pending?.cancel()
    let snapshot = settings
    let wait = now ? Duration.zero : delay
    pending = Task { [weak self] in
      guard (try? await Task.sleep(for: wait)) != nil, let self else { return }
      do {
        let saved = try await self.service.save(snapshot)
        guard !Task.isCancelled else { return }
        self.settings = saved
        self.error = nil
      } catch is CancellationError {
        return
      } catch {
        self.error = LiveUserError(error).message ?? String(localized: "The change could not be saved.")
        if let stored = try? await self.service.settings() { self.settings = stored }
      }
    }
  }
}

private extension Array where Element == String {
  mutating func toggle(_ value: String) {
    if contains(value) { removeAll { $0 == value } } else { append(value) }
  }
}
