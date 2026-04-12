import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
  @Published var publicUsername: String = ""
  @Published var bio: String = ""
  @Published private(set) var isSaving: Bool = false
  @Published var errorMessage: String?
  @Published var infoMessage: String?

  private let profileService: ProfileServiceProtocol
  private let sessionProvider: () -> SessionSnapshot?

  init(
    profileService: ProfileServiceProtocol,
    sessionProvider: @escaping () -> SessionSnapshot?
  ) {
    self.profileService = profileService
    self.sessionProvider = sessionProvider
  }

  var userID: String {
    sessionProvider()?.userID ?? ""
  }

  func save() async {
    guard !isSaving else { return }
    isSaving = true
    errorMessage = nil
    infoMessage = nil
    do {
      try await profileService.update(publicUsername: publicUsername, bio: bio)
      infoMessage = "Profile saved"
      isSaving = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to save profile."
      isSaving = false
    } catch {
      errorMessage = "Unable to save profile."
      isSaving = false
    }
  }
}
