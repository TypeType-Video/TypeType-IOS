import Foundation

@MainActor
final class LiveSubscriptionGroupsViewModel: ObservableObject {
  @Published private(set) var groups: [LiveSubscriptionGroup]
  @Published private(set) var channels: [LiveSubscription]
  @Published private(set) var memberships: [
    LiveSubscriptionGroupMembership
  ]
  @Published private(set) var isRefreshing = false
  @Published private(set) var isMutating = false
  @Published var errorMessage: String?

  private let source: LiveSubscriptionsViewModel

  init(source: LiveSubscriptionsViewModel) {
    groups = source.groups
    channels = source.channels
    memberships = source.memberships
    self.source = source
  }

  var sortedGroups: [LiveSubscriptionGroup] {
    groups.sorted {
      $0.name.localizedCaseInsensitiveCompare($1.name)
        == .orderedAscending
    }
  }

  var hasChannels: Bool {
    !channels.isEmpty
  }

  func groupIDs(for channel: LiveSubscription) -> Set<String> {
    source.groupIDs(for: channel.channelURL)
  }

  func refresh() async {
    guard !isRefreshing else { return }
    isRefreshing = true
    defer { isRefreshing = false }
    await source.reload()
    syncFromSource()
  }

  func createGroup(named rawName: String) async {
    await source.createGroup(named: rawName)
    syncFromSource()
  }

  func renameGroup(
    _ group: LiveSubscriptionGroup,
    to rawName: String
  ) async {
    await source.renameGroup(group, to: rawName)
    syncFromSource()
  }

  func deleteGroup(_ group: LiveSubscriptionGroup) async {
    await source.deleteGroup(group)
    syncFromSource()
  }

  func toggleMembership(
    _ channel: LiveSubscription,
    in group: LiveSubscriptionGroup
  ) async {
    await source.toggleGroupMembership(channel, in: group)
    syncFromSource()
  }

  private func syncFromSource() {
    groups = source.groups
    channels = source.channels
    memberships = source.memberships
    errorMessage = source.groupActionError
  }
}
