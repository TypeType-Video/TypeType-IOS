import Foundation

@MainActor
final class LiveAdminBugReportViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var detail: LiveAdminBugReportDetail?
  @Published var status: String
  @Published private(set) var isBusy = false
  @Published private(set) var githubURL: URL?
  @Published private(set) var errorMessage: String?

  private let id: String
  private let service: LiveBugReportsServiceProtocol

  init(report: LiveAdminBugReport, service: LiveBugReportsServiceProtocol) {
    id = report.id
    status = report.status
    githubURL = report.githubIssueURL
    self.service = service
  }

  func prepare() async {
    guard state == .idle else { return }
    state = .loading
    do {
      let detail = try await service.detail(id: id)
      self.detail = detail
      status = detail.status
      githubURL = detail.githubIssueURL
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func saveStatus() async {
    await perform {
      try await service.updateStatus(id: id, status: status)
    }
  }

  func createGitHubIssue() async {
    await perform {
      githubURL = try await service.createGitHubIssue(id: id)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func perform(_ operation: () async throws -> Void) async {
    guard !isBusy else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      try await operation()
    } catch {
      errorMessage = text(for: error)
    }
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The bug report could not be updated."
  }
}
