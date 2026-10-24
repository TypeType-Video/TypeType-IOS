import SwiftUI

struct DemoAdminUsersView: View {
  @EnvironmentObject private var session: DemoSessionStore
  @State private var query = ""
  @State private var role = "All"
  @State private var page = 0
  private let pageSize = 2

  var body: some View {
    List {
      Section {
        Picker("Role", selection: $role) {
          ForEach(
            ["All", "admin", "moderator", "user", "Suspended"],
            id: \.self
          ) {
            Text($0.capitalized).tag($0)
          }
        }
      }

      Section {
        ForEach(pagedUsers) { user in
          NavigationLink {
            DemoAdminUserDetailView(userID: user.id)
          } label: {
            HStack(spacing: 12) {
              DemoProfileAvatarView(size: 42)
              VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                Text(user.email)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              VStack(alignment: .trailing, spacing: 2) {
                Text(user.role.capitalized)
                  .font(.caption.weight(.semibold))
                if user.isSuspended {
                  Text("Suspended")
                    .font(.caption2)
                    .foregroundStyle(.red)
                }
              }
            }
          }
        }
        if filteredUsers.count > pageSize {
          pagination
        }
      } header: { Text("\(filteredUsers.count) users").liveSectionHeader() }
    }
    .searchable(text: $query, prompt: "Name, email, or ID")
    .onChange(of: query) { page = 0 }
    .onChange(of: role) { page = 0 }
    .overlay {
      if filteredUsers.isEmpty {
        ContentUnavailableView.search(text: query)
      }
    }
  }

  private var filteredUsers: [DemoAdminUser] {
    session.adminUsers.filter { user in
      let matchesRole =
        role == "All"
        || user.role == role
        || (role == "Suspended" && user.isSuspended)
      let haystack = "\(user.name) \(user.email) \(user.id)".lowercased()
      return matchesRole && (query.isEmpty || haystack.contains(query.lowercased()))
    }
  }

  private var pagedUsers: [DemoAdminUser] {
    let start = min(page * pageSize, filteredUsers.count)
    let end = min(start + pageSize, filteredUsers.count)
    return Array(filteredUsers[start..<end])
  }

  private var pagination: some View {
    HStack {
      Button("Previous") { page = max(0, page - 1) }
        .disabled(page == 0)
      Spacer()
      Text("Page \(page + 1) / \(pageCount)")
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
      Spacer()
      Button("Next") { page = min(pageCount - 1, page + 1) }
        .disabled(page >= pageCount - 1)
    }
  }

  private var pageCount: Int {
    max(1, (filteredUsers.count + pageSize - 1) / pageSize)
  }
}
