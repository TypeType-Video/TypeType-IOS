import SwiftUI
import UIKit

struct DemoAdminIssueDetailView: View {
  @EnvironmentObject private var session: DemoSessionStore
  let issueID: String

  var body: some View {
    Form {
      if let issue {
        Section {
          LabeledContent("Reporter", value: issue.reporter)
          LabeledContent("Category", value: issue.category)
          Text(issue.detail)
        } header: { Text("Report").liveSectionHeader() }

        Section {
          Picker("Status", selection: statusBinding) {
            Text("Open").tag("Open")
            Text("Triaged").tag("Triaged")
            Text("Resolved").tag("Resolved")
          }
        } header: { Text("Status").liveSectionHeader() }

        Section {
          if let githubIssue = issue.githubIssue {
            LabeledContent("Issue", value: githubIssue)
              .textSelection(.enabled)
          } else {
            Button("Create GitHub issue") {
              createGitHubIssue()
            }
          }
        } header: { Text("GitHub").liveSectionHeader() }

        Section {
          Text(issue.diagnostics)
            .font(.caption.monospaced())
          Button("Copy diagnostics") {
            UIPasteboard.general.string = issue.diagnostics
          }
        } header: { Text("Diagnostics").liveSectionHeader() }
      }
    }
    .navigationTitle(issue?.title ?? "Issue")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var index: Int? {
    session.adminIssues.firstIndex { $0.id == issueID }
  }

  private var issue: DemoAdminIssue? {
    index.map { session.adminIssues[$0] }
  }

  private var statusBinding: Binding<String> {
    Binding(
      get: { issue?.status ?? "Open" },
      set: { value in
        guard let index else { return }
        session.adminIssues[index].status = value
      }
    )
  }

  private func createGitHubIssue() {
    guard let index else { return }
    session.adminIssues[index].githubIssue =
      "https://github.com/TypeType-Video/TypeType/issues/mock-\(issueID)"
  }
}
