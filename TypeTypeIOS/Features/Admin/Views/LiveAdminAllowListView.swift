import SwiftUI

struct LiveAdminAllowListView: View {
  let accessService: LiveAdminAccessServiceProtocol
  @StateObject private var viewModel: LiveAdminAllowListViewModel
  @State private var editor: Editor?
  @State private var selectedUser: LiveAdminAllowListUser?

  init(
    admin: LiveAdminServiceProtocol,
    access: LiveAdminAccessServiceProtocol,
    controls: LiveContentControlsServiceProtocol
  ) {
    accessService = access
    _viewModel = StateObject(
      wrappedValue: LiveAdminAllowListViewModel(
        admin: admin,
        access: access,
        controls: controls
      )
    )
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .idle, .loading:
        ProgressView("Loading access rules")
      case let .failed(message):
        ContentUnavailableView {
          Label("Access rules unavailable", systemImage: "lock.trianglebadge.exclamationmark")
        } description: {
          Text(message)
        } actions: {
          Button("Try again") { Task { await viewModel.reload() } }
        }
      case .loaded:
        list
      }
    }
    .navigationTitle("Allow list")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(item: $selectedUser) { user in
      LiveAdminUserAccessView(
        userID: user.id,
        service: accessService
      )
    }
    .searchable(
      text: $viewModel.userQuery,
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: "Find a user"
    )
    .onChange(of: viewModel.userQuery) {
      viewModel.userQueryChanged()
    }
    .task { await viewModel.prepare() }
    .sheet(item: $editor) { item in
      LiveAdminAllowedItemEditor(
        title: item == .channel ? "Add global channel" : "Add global playlist",
        label: item == .channel ? "Channel" : "Playlist",
        onSave: item == .channel
          ? viewModel.addChannel
          : viewModel.addPlaylist
      )
    }
  }

  private var list: some View {
    List {
      Section {
        Toggle(
          "Restrict to allow list",
          isOn: Binding(
            get: { viewModel.settings?.accessMode == "allow_list" },
            set: { value in
              Task { await viewModel.setRestricted(value) }
            }
          )
        )
        .disabled(viewModel.isBusy)
      } header: { Text("Entire instance").liveSectionHeader() }

      usersSection

      Section {
        ForEach(viewModel.channels) { item in
          LiveAdminAllowedChannelRow(item: item)
            .swipeActions {
              Button("Remove", role: .destructive) {
                Task { await viewModel.removeChannel(item) }
              }
            }
        }
        Button("Add channel", systemImage: "plus") {
          editor = .channel
        }
      } header: { Text("Global channels").liveSectionHeader() }

      Section {
        ForEach(viewModel.playlists) { item in
          LiveAdminAllowedPlaylistRow(item: item)
            .swipeActions {
              Button("Remove", role: .destructive) {
                Task { await viewModel.removePlaylist(item) }
              }
            }
        }
        Button("Add playlist", systemImage: "plus") {
          editor = .playlist
        }
      } header: { Text("Global playlists").liveSectionHeader() }
    }
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(DemoTheme.background)
      .listStyle(.insetGrouped)
    .refreshable { await viewModel.reload() }
  }

  @ViewBuilder
  private var usersSection: some View {
    let query = viewModel.userQuery.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    Section(query.isEmpty ? "Managed users" : "Matching users") {
      if !query.isEmpty && viewModel.isSearchingUsers {
        HStack(spacing: 10) {
          ProgressView()
          Text("Searching users")
            .foregroundStyle(.secondary)
        }
      } else {
        let users = query.isEmpty
          ? viewModel.managedUsers
          : viewModel.userResults
        if users.isEmpty {
          Text(
            query.isEmpty
              ? "No user-specific access rules"
              : "No matching users"
          )
          .foregroundStyle(.secondary)
        } else {
          ForEach(users) { user in
            Button {
              selectedUser = user
            } label: {
              LiveAdminAccessUserRow(user: user)
            }
            .buttonStyle(.plain)
          }
        }
        if query.isEmpty {
          DemoIncrementalLoadingTrigger(
            canLoadMore: viewModel.canLoadMoreManagedUsers,
            isLoading: viewModel.isLoadingMoreUsers,
            label: "Loading more managed users",
            identifier: "live.admin.allow-list.loading-more-users"
          ) {
            Task { await viewModel.loadMoreManagedUsers() }
          }
        }
      }
    }
  }

  private enum Editor: String, Identifiable {
    case channel, playlist
    var id: String { rawValue }
  }
}

private struct LiveAdminAccessUserRow: View {
  let user: LiveAdminAllowListUser

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "person.crop.circle")
        .font(.title2)
        .foregroundStyle(DemoTheme.accent)
      VStack(alignment: .leading, spacing: 2) {
        Text(user.name)
          .font(.body.weight(.semibold))
          .foregroundStyle(.primary)
        Text(user.email)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Text(
        user.accessMode == "allow_list"
          ? "Restricted"
          : "Unrestricted"
      )
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
    }
    .contentShape(Rectangle())
  }
}
