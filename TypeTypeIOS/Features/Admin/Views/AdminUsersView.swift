import SwiftUI

struct AdminUsersView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: AdminUsersViewModel

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

  var body: some View {
    NavigationStack {
      VStack(spacing: 8) {
        feedbackSection

        if viewModel.isLoading && viewModel.users.isEmpty {
          ProgressView("Loading users...")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
          List {
            ForEach(viewModel.users) { user in
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
        }
      }
      .navigationTitle("Admin")
      .task { await viewModel.reload() }
    }
  }
}
