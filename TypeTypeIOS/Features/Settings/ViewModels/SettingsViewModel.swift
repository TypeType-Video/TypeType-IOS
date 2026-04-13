import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
  @Published var draft: UserSettings = .default
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isSaving: Bool = false
  @Published var errorMessage: String?
  @Published var infoMessage: String?

  private let service: UserSettingsServiceProtocol
  private let recommendationFeedbackService: RecommendationFeedbackServiceProtocol

  init(
    service: UserSettingsServiceProtocol,
    recommendationFeedbackService: RecommendationFeedbackServiceProtocol
  ) {
    self.service = service
    self.recommendationFeedbackService = recommendationFeedbackService
  }

  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    do {
      draft = try await service.get()
      DefaultServiceStore.set(draft.defaultService)
      RecommendationContextStore.set(serviceID: draft.defaultService)
      RecommendationTrackingPreferenceStore.set(draft.recommendationPersonalizationEnabled)
      recommendationFeedbackService.setEnabled(draft.recommendationPersonalizationEnabled)
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load settings."
      isLoading = false
    } catch {
      errorMessage = "Unable to load settings."
      isLoading = false
    }
  }

  func save() async {
    guard !isSaving else { return }
    isSaving = true
    errorMessage = nil
    infoMessage = nil
    do {
      draft = try await service.update(draft)
      DefaultServiceStore.set(draft.defaultService)
      RecommendationContextStore.set(serviceID: draft.defaultService)
      RecommendationTrackingPreferenceStore.set(draft.recommendationPersonalizationEnabled)
      recommendationFeedbackService.setEnabled(draft.recommendationPersonalizationEnabled)
      infoMessage = "Settings saved"
      isSaving = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to save settings."
      isSaving = false
    } catch {
      errorMessage = "Unable to save settings."
      isSaving = false
    }
  }
}
