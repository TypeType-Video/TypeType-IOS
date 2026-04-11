import SwiftUI

struct AdminUsersView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: AdminUsersViewModel
  @State private var searchText: String = ""
  @State private var roleFilter: String = "all"

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: AdminUsersViewModel(service: coordinator.dependencies.adminService)
    )
  }

  @ViewBuilder
  private var feedbackSection: some View {
    if let errorMessage = viewModel.errorMessage {
      Text(errorMessage)
        .font(.footnote)
        .foregroundStyle(.red)
        .padding(.horizontal)
    }
    if let tokenMessage = viewModel.tokenMessage {
      Text(tokenMessage)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .textSelection(.enabled)
    }
  }

  private var filteredUsers: [AdminUser] {
    viewModel.users.filter { user in
      let roleMatch = roleFilter == "all" || user.role.rawValue == roleFilter
      guard roleMatch else { return false }
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      guard !query.isEmpty else { return true }
      let haystack = "\(user.name) \(user.email) \(user.id)".lowercased()
      return haystack.contains(query)
    }
  }

  @ViewBuilder
  private var listContent: some View {
    if filteredUsers.isEmpty {
      ContentUnavailableView("No users", systemImage: "person.2.slash")
        .frame(maxHeight: .infinity)
    } else {
      List {
        ForEach(filteredUsers) { user in
          NavigationLink {
            AdminUserDetailView(
              user: user,
              onRole: { role in
                Task { await viewModel.changeRole(user: user, to: role) }
              },
              onSuspend: {
                Task { await viewModel.toggleSuspension(for: user) }
              },
              onResetToken: {
                Task { await viewModel.createResetToken(for: user) }
              }
            )
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 3) {
                Text(user.name)
                Text(user.email)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              Text(user.role.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
          }
        }

        if viewModel.canLoadMore {
          Button(viewModel.isLoadingMore ? "Loading..." : "Load more") {
            Task { await viewModel.loadMore() }
          }
          .disabled(viewModel.isLoadingMore)
        }
      }
      .listStyle(.plain)
      .refreshable { await viewModel.reload() }
      .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 8) {
        feedbackSection

        if viewModel.isLoading && viewModel.users.isEmpty {
          ProgressView("Loading users...")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
          Picker("Role", selection: $roleFilter) {
            Text("All").tag("all")
            Text("Admin").tag("admin")
            Text("Moderator").tag("moderator")
            Text("User").tag("user")
          }
          .pickerStyle(.segmented)
          .padding(.horizontal)

          listContent
        }
      }
      .navigationTitle("Admin")
      .task { await viewModel.reload() }
    }
  }
}
