import SwiftUI

struct LiveAdminBugReportView: View {
  let canCreateGitHubIssue: Bool
  @StateObject private var viewModel: LiveAdminBugReportViewModel

  init(
    report: LiveAdminBugReport,
    service: LiveBugReportsServiceProtocol,
    canCreateGitHubIssue: Bool
  ) {
    self.canCreateGitHubIssue = canCreateGitHubIssue
    _viewModel = StateObject(
      wrappedValue: LiveAdminBugReportViewModel(
        report: report,
        service: service
      )
    )
  }

  var body: some View {
    content
      .navigationTitle("Bug report")
      .navigationBarTitleDisplayMode(.inline)
      .task { await viewModel.prepare() }
      .alert("Bug report", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView(
        "Report unavailable",
        systemImage: "ladybug",
        description: Text(message)
      ).liveThemedEmptyState()
    case .loaded:
      if let detail = viewModel.detail {
        Form {
          Section {
            LabeledContent("Category", value: detail.category)
            LabeledContent("User", value: detail.userEmail)
            Text(detail.description)
              .textSelection(.enabled)
          } header: { Text("Report").liveSectionHeader() }
          Section {
            LabeledContent("Route", value: detail.context.route)
            LabeledContent(
              "Language",
              value: detail.context.browserLanguage
            )
            LabeledContent("Client", value: detail.context.userAgent)
            if let videoURL = detail.context.videoURL {
              Text(videoURL)
                .font(.caption.monospaced())
                .textSelection(.enabled)
            }
          } header: { Text("Context").liveSectionHeader() }
          Section {
            Picker("Status", selection: $viewModel.status) {
              Text("New").tag("new")
              Text("Triaged").tag("triaged")
              Text("In progress").tag("in_progress")
              Text("Fixed").tag("fixed")
              Text("Closed").tag("closed")
            }
            Button("Update status") {
              Task { await viewModel.saveStatus() }
            }
            .disabled(viewModel.isBusy)
          } header: { Text("Workflow").liveSectionHeader() }
          Section {
            if let url = viewModel.githubURL {
              Link("Open GitHub issue", destination: url)
            } else if canCreateGitHubIssue {
              Button("Create GitHub issue") {
                Task { await viewModel.createGitHubIssue() }
              }
              .disabled(viewModel.isBusy)
            } else {
              Text("Only administrators can create GitHub issues.")
                .foregroundStyle(.secondary)
            }
          } header: { Text("GitHub").liveSectionHeader() }
        }
          .liveThemedList()
      }
    }
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
