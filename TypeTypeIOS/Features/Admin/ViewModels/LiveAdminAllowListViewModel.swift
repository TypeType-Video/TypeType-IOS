import Foundation

@MainActor
final class LiveAdminAllowListViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var settings: LiveAdminSettings?
  @Published private(set) var channels: [LiveContentControlItem] = []
  @Published private(set) var playlists: [LiveAllowedPlaylistItem] = []
  @Published var userQuery = ""
  @Published private(set) var managedUsers: [LiveAdminAllowListUser] = []
  @Published private(set) var userResults: [LiveAdminAllowListUser] = []
  @Published private(set) var isSearchingUsers = false
  @Published private(set) var isLoadingMoreUsers = false
  @Published private(set) var isBusy = false

  private let admin: LiveAdminServiceProtocol
  private let access: LiveAdminAccessServiceProtocol
  private let controls: LiveContentControlsServiceProtocol
  private var managedUsersNextPage: String?
  private var searchTask: Task<Void, Never>?

  deinit {
    searchTask?.cancel()
  }

  init(
    admin: LiveAdminServiceProtocol,
    access: LiveAdminAccessServiceProtocol,
    controls: LiveContentControlsServiceProtocol
  ) {
    self.admin = admin
    self.access = access
    self.controls = controls
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      async let settings = admin.settings()
      async let channels = controls.items(kind: .allowedChannels)
      async let playlists = access.globalPlaylists()
      async let managedUsers = access.managedUsers(nextPage: nil)
      self.settings = try await settings
      self.channels = try await channels.filter { $0.global == true }
      self.playlists = try await playlists
      let usersPage = try await managedUsers
      self.managedUsers = usersPage.items
      managedUsersNextPage = usersPage.nextPage
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  var canLoadMoreManagedUsers: Bool {
    managedUsersNextPage?.isEmpty == false
  }

  func loadMoreManagedUsers() async {
    guard !isLoadingMoreUsers,
      let managedUsersNextPage,
      !managedUsersNextPage.isEmpty
    else {
      return
    }
    isLoadingMoreUsers = true
    defer { isLoadingMoreUsers = false }
    do {
      let page = try await access.managedUsers(
        nextPage: managedUsersNextPage
      )
      let existing = Set(managedUsers.map(\.id))
      managedUsers.append(contentsOf: page.items.filter {
        !existing.contains($0.id)
      })
      self.managedUsersNextPage = page.nextPage
    } catch {
      state = .failed(text(for: error))
    }
  }

  func userQueryChanged() {
    searchTask?.cancel()
    let query = userQuery.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard !query.isEmpty else {
      userResults = []
      isSearchingUsers = false
      return
    }
    isSearchingUsers = true
    searchTask = Task {
      do {
        try await Task.sleep(for: .milliseconds(300))
        let users = try await access.searchUsers(query: query)
        try Task.checkCancellation()
        guard userQuery.trimmingCharacters(
          in: .whitespacesAndNewlines
        ) == query else {
          return
        }
        userResults = users
        isSearchingUsers = false
      } catch is CancellationError {
        return
      } catch {
        guard !Task.isCancelled else { return }
        userResults = []
        isSearchingUsers = false
      }
    }
  }

  func setRestricted(_ restricted: Bool) async {
    guard var settings, !isBusy else { return }
    isBusy = true
    defer { isBusy = false }
    settings.accessMode = restricted ? "allow_list" : "unrestricted"
    do {
      self.settings = try await admin.updateSettings(settings)
    } catch {
      state = .failed(text(for: error))
    }
  }

  func addChannel(url: String, name: String) async -> Bool {
    await mutate {
      _ = try await controls.add(
        kind: .allowedChannels,
        item: LiveContentControlItem(
          url: url,
          name: name.isEmpty ? nil : name,
          global: true
        )
      )
    }
  }

  func addPlaylist(url: String, title: String) async -> Bool {
    await mutate {
      try await access.addGlobalPlaylist(
        LiveAllowedPlaylistItem(
          url: url,
          title: title.isEmpty ? nil : title,
          global: true
        )
      )
    }
  }

  func removeChannel(_ item: LiveContentControlItem) async {
    _ = await mutate {
      try await controls.remove(kind: .allowedChannels, url: item.url)
    }
  }

  func removePlaylist(_ item: LiveAllowedPlaylistItem) async {
    _ = await mutate {
      try await access.removeGlobalPlaylist(url: item.url)
    }
  }

  private func mutate(
    _ operation: () async throws -> Void
  ) async -> Bool {
    guard !isBusy else { return false }
    isBusy = true
    defer { isBusy = false }
    do {
      try await operation()
      await reload()
      return true
    } catch {
      state = .failed(text(for: error))
      return false
    }
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The allow list could not be updated."
  }
}
