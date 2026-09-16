import Foundation

@MainActor
final class LiveSubscriptionsViewModel: ObservableObject {
  enum Section: String, CaseIterable, Identifiable {
    case videos
    case channels

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
  }

  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published var section = Section.videos
  @Published private(set) var state = State.idle
  @Published private(set) var videos: [LiveVideoItem] = []
  @Published private(set) var channels: [LiveSubscription] = []
  @Published private(set) var isLoadingMore = false
  @Published private(set) var groups: [LiveSubscriptionGroup] = []
  @Published private(set) var memberships: [
    LiveSubscriptionGroupMembership
  ] = []
  @Published var filter = LiveSubscriptionFilter.all
  @Published private(set) var isMutatingGroups = false
  @Published var groupActionError: String?

  private let service: LiveSubscriptionsServiceProtocol
  private var nextPage: String?
  private var loadTask: Task<Void, Never>?

  init(service: LiveSubscriptionsServiceProtocol) {
    self.service = service
  }

  deinit {
    loadTask?.cancel()
  }

  var canLoadMore: Bool {
    nextPage?.isEmpty == false
  }

  var visibleVideos: [LiveVideoItem] {
    videos
  }

  var filterLabel: String {
    switch filter {
    case .all:
      return "All subscriptions"
    case .ungrouped:
      return "Ungrouped"
    case let .group(_, name):
      return name
    }
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    loadTask?.cancel()
    state = .loading
    do {
      async let channelRequest = service.subscriptions()
      async let groupRequest = service.groups()
      async let membershipRequest = service.memberships()
      async let feedRequest = service.feed(
        nextPage: nil,
        filter: filter
      )
      let (loadedChannels, loadedGroups, loadedMemberships, page) = try await (
        channelRequest,
        groupRequest,
        membershipRequest,
        feedRequest
      )
      try Task.checkCancellation()
      channels = loadedChannels
      groups = loadedGroups
      memberships = loadedMemberships
      videos = uniqueVisible(page.videos)
      nextPage = page.nextPage
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      state = .failed(message(for: error))
    }
  }

  func loadMore() async {
    guard !isLoadingMore, let nextPage, !nextPage.isEmpty else {
      return
    }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await service.feed(
        nextPage: nextPage,
        filter: filter
      )
      let existing = Set(videos.map(\.canonicalID))
      videos.append(
        contentsOf: uniqueVisible(page.videos).filter {
          !existing.contains($0.canonicalID)
        }
      )
      self.nextPage = page.nextPage
    } catch is CancellationError {
      return
    } catch let error as NetworkError {
      if case .statusCode(409, _) = error {
        await reload()
        return
      }
      state = .failed(message(for: error))
    } catch {
      state = .failed(message(for: error))
    }
  }

  func selectFilter(_ newFilter: LiveSubscriptionFilter) async {
    guard filter != newFilter else { return }
    filter = newFilter
    loadTask?.cancel()
    state = .loading
    do {
      let page = try await service.feed(nextPage: nil, filter: filter)
      videos = uniqueVisible(page.videos)
      nextPage = page.nextPage
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      state = .failed(message(for: error))
    }
  }

  func unsubscribe(_ channel: LiveSubscription) async {
    do {
      try await service.unsubscribe(channelURL: channel.channelURL)
      channels.removeAll { $0.id == channel.id }
      await reload()
    } catch {
      state = .failed(message(for: error))
    }
  }

  func groupIDs(for channelURL: String) -> Set<String> {
    let normalized = normalizedChannelURL(channelURL)
    guard let membership = memberships.first(
      where: { normalizedChannelURL($0.channelURL) == normalized }
    ) else {
      return []
    }
    return Set(membership.groupIDs)
  }

  func createGroup(named rawName: String) async {
    let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty, !isMutatingGroups else { return }
    await performGroupMutation {
      let group = try await self.service.createGroup(name: name)
      self.groups.append(group)
      self.groups.sort {
        $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
      }
    }
  }

  func renameGroup(_ group: LiveSubscriptionGroup, to rawName: String) async {
    let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty, !isMutatingGroups else { return }
    await performGroupMutation {
      try await self.service.renameGroup(id: group.id, name: name)
      try await self.refreshGroupData()
      if case let .group(id, _) = self.filter, id == group.id {
        self.filter = .group(id: group.id, name: name)
      }
    }
  }

  func deleteGroup(_ group: LiveSubscriptionGroup) async {
    guard !isMutatingGroups else { return }
    await performGroupMutation {
      try await self.service.deleteGroup(id: group.id)
      self.groups.removeAll { $0.id == group.id }
      self.memberships = self.memberships.map { membership in
        LiveSubscriptionGroupMembership(
          channelURL: membership.channelURL,
          name: membership.name,
          avatarURL: membership.avatarURL,
          subscribedAt: membership.subscribedAt,
          groupIDs: membership.groupIDs.filter { $0 != group.id }
        )
      }
      if case let .group(id, _) = self.filter, id == group.id {
        await self.selectFilter(.all)
      }
    }
  }

  func toggleGroupMembership(
    _ channel: LiveSubscription,
    in group: LiveSubscriptionGroup
  ) async {
    guard !isMutatingGroups else { return }
    let isMember = groupIDs(for: channel.channelURL).contains(group.id)
    await performGroupMutation {
      if isMember {
        try await self.service.removeChannel(
          channel.channelURL,
          fromGroup: group.id
        )
      } else {
        try await self.service.addChannels(
          [channel.channelURL],
          toGroup: group.id
        )
      }
      try await self.refreshGroupData()
    }
  }

  private func uniqueVisible(
    _ candidates: [LiveVideoItem]
  ) -> [LiveVideoItem] {
    var seen: Set<String> = []
    return candidates.filter {
      seen.insert($0.canonicalID).inserted
    }
  }

  private func refreshGroupData() async throws {
    async let groupRequest = service.groups()
    async let membershipRequest = service.memberships()
    let (loadedGroups, loadedMemberships) = try await (
      groupRequest,
      membershipRequest
    )
    groups = loadedGroups
    memberships = loadedMemberships
  }

  private func performGroupMutation(
    _ operation: @escaping () async throws -> Void
  ) async {
    isMutatingGroups = true
    groupActionError = nil
    defer { isMutatingGroups = false }
    do {
      try await operation()
    } catch is CancellationError {
      return
    } catch {
      groupActionError = (error as? LocalizedError)?.errorDescription
        ?? "Subscription group could not be updated."
    }
  }

  private func normalizedChannelURL(_ value: String) -> String {
    value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      .lowercased()
  }

  private func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Subscriptions could not be loaded."
  }
}
