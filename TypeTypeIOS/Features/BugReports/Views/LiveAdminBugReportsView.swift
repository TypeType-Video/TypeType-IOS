import SwiftUI

struct LiveAdminBugReportsView: View {
  let service: LiveBugReportsServiceProtocol
  let canCreateGitHubIssue: Bool
  @StateObject private var viewModel: LiveAdminBugReportsViewModel
  @State private var selected: LiveAdminBugReport?

  init(
    service: LiveBugReportsServiceProtocol,
    canCreateGitHubIssue: Bool
  ) {
    self.service = service
    self.canCreateGitHubIssue = canCreateGitHubIssue
    _viewModel = StateObject(
      wrappedValue: LiveAdminBugReportsViewModel(service: service)
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      filterBar
      content
    }
    .navigationTitle("Bug reports")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(item: $selected) { report in
      LiveAdminBugReportView(
        report: report,
        service: service,
        canCreateGitHubIssue: canCreateGitHubIssue
      )
    }
    .task { await viewModel.prepare() }
  }

  private var filterBar: some View {
    HStack {
      Picker("Status", selection: $viewModel.status) {
        Text("All statuses").tag("")
        Text("New").tag("new")
        Text("Triaged").tag("triaged")
        Text("In progress").tag("in_progress")
        Text("Fixed").tag("fixed")
        Text("Closed").tag("closed")
      }
      Picker("Category", selection: $viewModel.category) {
        Text("All categories").tag("")
        Text("Player").tag("player")
        Text("Audio").tag("audio_language")
        Text("Subtitles").tag("subtitles")
        Text("Interface").tag("ui")
        Text("Functionality").tag("functionality")
      }
      Button("Apply") {
        Task { await viewModel.reload() }
      }
      .buttonStyle(.bordered)
    }
    .padding()
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView(
        "Reports unavailable",
        systemImage: "ladybug",
        description: Text(message)
      )
    case .loaded:
      List {
        Section {
          ForEach(viewModel.reports) { report in
            Button {
              selected = report
            } label: {
              LiveAdminBugReportRow(report: report)
            }
            .buttonStyle(.plain)
          }
          DemoIncrementalLoadingTrigger(
            canLoadMore: viewModel.canLoadMore,
            isLoading: viewModel.isLoadingMore,
            label: "Loading more reports",
            identifier: "live.admin.reports.loading-more"
          ) {
            Task { await viewModel.loadMore() }
          }
        } header: { Text("\(viewModel.total) reports").liveSectionHeader() }
      }
        .id(DemoTheme.renderToken)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DemoTheme.background)
      .listStyle(.plain)
      .refreshable { await viewModel.reload() }
    }
  }
}
