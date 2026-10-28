import SwiftUI

struct LiveAdminUsersView: View {
  let service: LiveAdminServiceProtocol
  let accessService: LiveAdminAccessServiceProtocol
  let currentUserID: String
  @StateObject private var viewModel: LiveAdminUsersViewModel
  @State private var selectedUser: LiveAdminUser?

  init(
    service: LiveAdminServiceProtocol,
    accessService: LiveAdminAccessServiceProtocol,
    currentUserID: String
  ) {
    self.service = service
    self.accessService = accessService
    self.currentUserID = currentUserID
    _viewModel = StateObject(
      wrappedValue: LiveAdminUsersViewModel(service: service)
    )
  }

  var body: some View {
    content
      .navigationTitle("Users")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(item: $selectedUser) { user in
        LiveAdminUserView(
          user: user,
          currentUserID: currentUserID,
          service: service,
          accessService: accessService
        )
      }
      .task { await viewModel.prepare() }
      .accessibilityIdentifier("live.admin.users")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .rows, count: 8)
    case let .failed(message):
      ContentUnavailableView {
        Label("Users unavailable", systemImage: "person.3")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      List {
        Section {
          ForEach(viewModel.users) { user in
            Button {
              selectedUser = user
            } label: {
              LiveAdminUserRow(user: user)
            }
            .buttonStyle(.plain)
          }
          DemoIncrementalLoadingTrigger(
            canLoadMore: viewModel.canLoadMore,
            isLoading: viewModel.isLoadingMore,
            label: "Loading more users",
            identifier: "live.admin.users.loading-more"
          ) {
            Task { await viewModel.loadMore() }
          }
        } header: { Text("\(viewModel.total) users").liveSectionHeader() }
      }
        .liveThemedList()
      .liveThemeRepaint()
      .listStyle(.plain)
      .refreshable { await viewModel.reload() }
    }
  }
}
