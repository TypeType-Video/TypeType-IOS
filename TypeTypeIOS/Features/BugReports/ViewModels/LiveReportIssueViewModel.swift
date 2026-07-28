import Foundation

@MainActor
final class LiveReportIssueViewModel: ObservableObject {
  @Published var category = "functionality"
  @Published var description = ""
  @Published var videoURL = ""
  @Published private(set) var isSubmitting = false
  @Published private(set) var created: LiveCreatedBugReport?
  @Published private(set) var errorMessage: String?

  private let service: LiveBugReportsServiceProtocol

  init(
    service: LiveBugReportsServiceProtocol,
    videoURL: String = ""
  ) {
    self.service = service
    self.videoURL = videoURL
  }

  func submit() async {
    guard !isSubmitting, description.count >= 20 else { return }
    isSubmitting = true
    defer { isSubmitting = false }
    do {
      created = try await service.create(
        category: category,
        description: description.trimmingCharacters(
          in: .whitespacesAndNewlines
        ),
        videoURL: videoURL.trimmingCharacters(
          in: .whitespacesAndNewlines
        ).nilIfEmpty
      )
    } catch {
      errorMessage = (error as? LocalizedError)?.errorDescription
        ?? "The report could not be submitted."
    }
  }

  func dismissError() {
    errorMessage = nil
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
