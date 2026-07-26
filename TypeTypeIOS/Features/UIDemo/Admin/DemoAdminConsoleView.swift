import SwiftUI

struct DemoAdminConsoleView: View {
  enum Section: String, CaseIterable, Identifiable {
    case settings = "Settings"
    case allowList = "Allow list"
    case users = "Users"
    case sessions = "Sessions"
    case issues = "Issues"

    var id: String { rawValue }
  }

  @State private var section = Section.settings

  var body: some View {
    VStack(spacing: 0) {
      Picker("Admin section", selection: $section) {
        ForEach(Section.allCases) { Text($0.rawValue).tag($0) }
      }
      .pickerStyle(.segmented)
      .padding()

      Group {
        switch section {
        case .settings:
          DemoAdminSettingsView()
        case .allowList:
          DemoAdminAllowListView()
        case .users:
          DemoAdminUsersView()
        case .sessions:
          DemoAdminSessionsView()
        case .issues:
          DemoAdminIssuesView()
        }
      }
    }
    .navigationTitle("Admin console")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("demo.admin.screen")
  }
}
