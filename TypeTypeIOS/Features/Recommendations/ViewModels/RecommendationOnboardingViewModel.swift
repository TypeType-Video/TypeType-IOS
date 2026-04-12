import Foundation

@MainActor
final class RecommendationOnboardingViewModel: ObservableObject {
  enum Mode {
    case onboarding
    case settings
  }

  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isSaving: Bool = false
  @Published private(set) var mode: Mode
  @Published private(set) var minTopics: Int = 3
  @Published private(set) var topicGroups: [RecommendationOnboardingTopicGroup] = []
  @Published private(set) var selectedTopics: [String] = []
  @Published private(set) var selectedChannels: [String] = []
  @Published private(set) var suggestedChannels: [SubscriptionChannel] = []
  @Published private(set) var requiresOnboarding: Bool = true
  @Published private(set) var completedAt: Int64?
  @Published var activeGroupID: String?
  @Published var channelInput: String = ""
  @Published private(set) var step: Int = 0
  @Published var errorMessage: String?
  @Published var infoMessage: String?

  private let service: RecommendationOnboardingServiceProtocol
  private let subscriptionsService: SubscriptionsServiceProtocol

  init(
    service: RecommendationOnboardingServiceProtocol,
    subscriptionsService: SubscriptionsServiceProtocol,
    mode: Mode = .onboarding
  ) {
    self.service = service
    self.subscriptionsService = subscriptionsService
    self.mode = mode
  }

  var canContinueFromTopics: Bool {
    selectedTopics.count >= minTopics
  }

  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    infoMessage = nil

    do {
      async let topicsRequest = service.topics()
      async let stateRequest = service.state()

      let topics = try await topicsRequest
      let state = try await stateRequest
      let channels: [SubscriptionChannel]
      do {
        channels = try await subscriptionsService.channels()
      } catch {
        channels = []
      }

      minTopics = max(1, topics.minTopics)
      topicGroups = topics.groups
      if activeGroupID == nil {
        activeGroupID = topics.groups.first?.id
      }
      requiresOnboarding = state.requiresOnboarding
      completedAt = state.completedAt
      selectedTopics = state.selectedTopics
      selectedChannels = normalized(state.selectedChannels)
      suggestedChannels = channels

      if mode == .onboarding && !state.requiresOnboarding {
        mode = .settings
      }
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load recommendation settings."
      isLoading = false
    } catch {
      errorMessage = "Unable to load recommendation settings."
      isLoading = false
    }
  }

  func toggleTopic(_ topic: String) {
    let key = topic.lowercased()
    if let index = selectedTopics.firstIndex(where: { $0.lowercased() == key }) {
      selectedTopics.remove(at: index)
    } else {
      selectedTopics.append(topic)
    }
  }

  func removeChannel(_ channelURL: String) {
    selectedChannels.removeAll(where: { $0.caseInsensitiveCompare(channelURL) == .orderedSame })
  }

  func addChannelFromInput() {
    let trimmed = channelInput.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    guard !containsChannel(trimmed) else {
      channelInput = ""
      return
    }
    selectedChannels.append(trimmed)
    channelInput = ""
  }

  func save() async {
    await saveAndMaybeReapply(whenNeeded: true)
  }

  func goToNextStep() {
    step = 1
  }

  func goToPreviousStep() {
    step = 0
  }

  func selectStep(_ value: Int) {
    step = max(0, min(1, value))
  }

  func finish() async {
    guard !isSaving else { return }
    guard canContinueFromTopics else {
      errorMessage = "Select at least \(minTopics) topics before finishing."
      return
    }
    await saveAndMaybeReapply(whenNeeded: false)
    guard errorMessage == nil else { return }
    do {
      isSaving = true
      let updated = try await service.complete()
      apply(updated)
      mode = .settings
      infoMessage = "Onboarding completed"
      isSaving = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to complete onboarding."
      isSaving = false
    } catch {
      errorMessage = "Unable to complete onboarding."
      isSaving = false
    }
  }

  func skip() async {
    guard !isSaving else { return }
    isSaving = true
    errorMessage = nil
    infoMessage = nil
    do {
      _ = try await service.savePreferences(selectedTopics: selectedTopics, selectedChannels: selectedChannels)
      let updated = try await service.skip()
      apply(updated)
      mode = .settings
      infoMessage = "You can revisit this anytime from settings."
      isSaving = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to skip onboarding."
      isSaving = false
    } catch {
      errorMessage = "Unable to skip onboarding."
      isSaving = false
    }
  }

  private func saveAndMaybeReapply(whenNeeded: Bool) async {
    guard !isSaving else { return }
    isSaving = true
    errorMessage = nil
    infoMessage = nil
    do {
      let updated = try await service.savePreferences(selectedTopics: selectedTopics, selectedChannels: selectedChannels)
      apply(updated)
      if whenNeeded && updated.requiresOnboarding == false {
        let reapplied = try await service.reapply()
        apply(reapplied)
      }
      infoMessage = "Preferences saved"
      isSaving = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to save preferences."
      isSaving = false
    } catch {
      errorMessage = "Unable to save preferences."
      isSaving = false
    }
  }

  private func apply(_ state: RecommendationOnboardingStateResponse) {
    requiresOnboarding = state.requiresOnboarding
    completedAt = state.completedAt
    selectedTopics = state.selectedTopics
    selectedChannels = normalized(state.selectedChannels)
  }

  private func containsChannel(_ value: String) -> Bool {
    selectedChannels.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame })
  }

  private func normalized(_ values: [String]) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []
    for raw in values {
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { continue }
      let key = trimmed.lowercased()
      guard !seen.contains(key) else { continue }
      seen.insert(key)
      result.append(trimmed)
    }
    return result
  }
}
