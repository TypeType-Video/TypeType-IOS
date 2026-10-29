import SwiftUI

struct LiveReportIssueView: View {
  @StateObject private var viewModel: LiveReportIssueViewModel

  init(
    service: LiveBugReportsServiceProtocol,
    videoURL: String = ""
  ) {
    _viewModel = StateObject(
      wrappedValue: LiveReportIssueViewModel(
        service: service,
        videoURL: videoURL
      )
    )
  }

  var body: some View {
    Form {
      if let created = viewModel.created {
        Section {
          ContentUnavailableView(
            "Report submitted",
            systemImage: "checkmark.circle.fill",
            description: Text(
              "Reference \(created.id) · \(created.status)"
            )
          ).liveThemedEmptyState()
        }
      } else {
        Section {
          Picker("Category", selection: $viewModel.category) {
            Text("Player").tag("player")
            Text("Audio language").tag("audio_language")
            Text("Subtitles").tag("subtitles")
            Text("Interface").tag("ui")
            Text("Functionality").tag("functionality")
          }
          TextField(
            "Describe what happened",
            text: $viewModel.description,
            axis: .vertical
          )
          .lineLimit(5...12)
          TextField(
            "Related video URL (optional)",
            text: $viewModel.videoURL
          )
          .keyboardType(.URL)
          .textInputAutocapitalization(.never)
        } header: { Text("Issue").liveSectionHeader() }
        Section {
          Button {
            Task { await viewModel.submit() }
          } label: {
            if viewModel.isSubmitting {
              ProgressView().frame(maxWidth: .infinity)
            } else {
              Text("Submit report").frame(maxWidth: .infinity)
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(
            viewModel.description
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .count < 20
              || viewModel.isSubmitting
          )
        }
      }
    }
      .liveGroupedList()
    .navigationTitle("Report a problem")
    .navigationBarTitleDisplayMode(.inline)
    .alert("Bug report", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .accessibilityIdentifier("live.bug-report.create")
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
