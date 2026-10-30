import Foundation

@MainActor
final class LiveProfileViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published var publicUsername: String
  @Published var bio: String
  @Published private(set) var isSaving = false
  @Published private(set) var message: String?
  @Published private(set) var errorMessage: String?

  private let service: LiveProfileServiceProtocol
  private let onProfileChanged: () async -> Void

  init(
    user: AuthUser,
    service: LiveProfileServiceProtocol,
    onProfileChanged: @escaping () async -> Void
  ) {
    publicUsername = user.publicUsername ?? ""
    bio = user.bio ?? ""
    self.service = service
    self.onProfileChanged = onProfileChanged
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    if publicUsername.isEmpty {
      state = .loaded
      return
    }
    do {
      let profile = try await service.publicProfile(
        username: publicUsername
      )
      publicUsername = profile.publicUsername
      bio = profile.bio ?? ""
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func saveProfile() async {
    await perform(success: "Profile updated") {
      try await service.updateProfile(
        publicUsername: publicUsername.trimmed.nilIfEmpty,
        bio: bio.trimmed.nilIfEmpty
      )
    }
  }

  func setEmoji(code: String) async {
    await perform(success: "Avatar updated") {
      try await service.setEmojiAvatar(code: code)
    }
  }

  func uploadAvatar(data: Data, mediaType: String) async {
    guard data.count <= 10 * 1_024 * 1_024 else {
      errorMessage = "Choose an image smaller than 10 MB."
      return
    }
    await perform(success: "Avatar updated") {
      _ = try await service.uploadAvatar(
        data: data,
        mediaType: mediaType
      )
    }
  }

  func clearAvatar() async {
    await perform(success: "Avatar cleared") {
      try await service.clearAvatar()
    }
  }

  func photoCouldNotBeRead() {
    errorMessage = "This photo could not be read. Choose another one."
  }

  func dismissError() {
    errorMessage = nil
  }

  private func perform(
    success: String,
    operation: () async throws -> Void
  ) async {
    guard !isSaving else { return }
    isSaving = true
    defer { isSaving = false }
    do {
      try await operation()
      await onProfileChanged()
      message = success
      state = .loaded
    } catch {
      errorMessage = text(for: error)
    }
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The profile could not be updated."
  }
}

private extension String {
  var trimmed: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
