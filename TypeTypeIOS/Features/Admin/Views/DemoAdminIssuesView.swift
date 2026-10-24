import SwiftUI

struct DemoAdminIssuesView: View {
  @EnvironmentObject private var session: DemoSessionStore
  @State private var query = ""
  @State private var status = "All"
  @State private var category = "All"
  @State private var page = 0
  private let pageSize = 2

  var body: some View {
    List {
      Section {
        Picker("Status", selection: $status) {
          ForEach(["All", "Open", "Triaged", "Resolved"], id: \.self) {
            Text($0).tag($0)
          }
        }
        Picker("Category", selection: $category) {
          ForEach(["All", "Playback", "Interface", "Import"], id: \.self) {
            Text($0).tag($0)
          }
        }
      }

      Section {
        ForEach(pagedIssues) { issue in
          NavigationLink {
            DemoAdminIssueDetailView(issueID: issue.id)
          } label: {
            VStack(alignment: .leading, spacing: 5) {
              HStack {
                Text(issue.id)
                  .font(.caption.monospaced())
                  .foregroundStyle(.secondary)
                Spacer()
                Text(issue.status)
                  .font(.caption.weight(.semibold))
              }
              Text(issue.title)
                .font(.subheadline.weight(.semibold))
              Text("\(issue.category) · \(issue.reporter)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
        if filteredIssues.count > pageSize {
          pagination
        }
      } header: { Text("\(filteredIssues.count) issues").liveSectionHeader() }
    }
    .searchable(text: $query, prompt: "Search issues")
    .onChange(of: query) { page = 0 }
    .onChange(of: status) { page = 0 }
    .onChange(of: category) { page = 0 }
    .accessibilityIdentifier("demo.admin.issues")
  }

  private var filteredIssues: [DemoAdminIssue] {
    session.adminIssues.filter { issue in
      let matchesStatus = status == "All" || issue.status == status
      let matchesCategory = category == "All" || issue.category == category
      let haystack = "\(issue.id) \(issue.title) \(issue.detail)".lowercased()
      return matchesStatus
        && matchesCategory
        && (query.isEmpty || haystack.contains(query.lowercased()))
    }
  }

  private var pagedIssues: [DemoAdminIssue] {
    let start = min(page * pageSize, filteredIssues.count)
    let end = min(start + pageSize, filteredIssues.count)
    return Array(filteredIssues[start..<end])
  }

  private var pagination: some View {
    HStack {
      Button("Previous", systemImage: "chevron.left") {
        page = max(0, page - 1)
      }
      .disabled(page == 0)

      Spacer()
      Text("Page \(page + 1) of \(pageCount)")
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
      Spacer()

      Button("Next", systemImage: "chevron.right") {
        page = min(pageCount - 1, page + 1)
      }
      .labelStyle(.titleAndIcon)
      .disabled(page >= pageCount - 1)
    }
  }

  private var pageCount: Int {
    max(1, (filteredIssues.count + pageSize - 1) / pageSize)
  }
}
