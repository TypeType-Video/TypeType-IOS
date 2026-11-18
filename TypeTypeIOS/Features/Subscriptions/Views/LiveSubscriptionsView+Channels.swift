import SwiftUI

extension LiveSubscriptionsView {
  var channelList: some View {
    Group {
      if viewModel.channels.isEmpty {
        ContentUnavailableView(
          "No subscriptions",
          systemImage: "person.2.slash",
          description: Text("Channels you subscribe to will appear here.")
        ).liveThemedEmptyState()
      } else {
        List {
          LiveSection {
            ForEach(filteredChannels) { channel in
              LiveSubscriptionChannelRow(
                channel: channel,
                groupNames: groupNames(for: channel),
                onOpen: { selectedChannel = channel },
                onUnsubscribe: { Task { await viewModel.unsubscribe(channel) } }
              ) {
                groupQuickActions(for: channel)
              }
            }
          } header: {
            Text("\(viewModel.channels.count) channels").liveSectionHeader()
          }
        }
        .liveGroupedList()
        .searchable(text: $channelQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search channels")
        .refreshable { await viewModel.reload() }
      }
    }
    .accessibilityIdentifier("live.subscriptions.channels")
  }

  var filteredChannels: [LiveSubscription] {
    let query = channelQuery.trimmingCharacters(in: .whitespaces)
    guard !query.isEmpty else { return viewModel.channels }
    return viewModel.channels.filter { $0.name.localizedStandardContains(query) }
  }

  func groupNames(for channel: LiveSubscription) -> [String] {
    let ids = viewModel.groupIDs(for: channel.channelURL)
    return viewModel.groups.filter { ids.contains($0.id) }.map(\.name)
  }

  @ViewBuilder
  func groupQuickActions(
    for channel: LiveSubscription
  ) -> some View {
    Section {
      if viewModel.groups.isEmpty {
        Text("No groups")
      } else {
        ForEach(viewModel.groups) { group in
          let isMember = viewModel.groupIDs(for: channel.channelURL)
            .contains(group.id)
          Button {
            Task {
              await viewModel.toggleGroupMembership(channel, in: group)
            }
          } label: {
            if isMember {
              Label(
                "Remove from \(group.name)",
                systemImage: "minus.circle"
              )
            } else {
              Label(
                "Add to \(group.name)",
                systemImage: "plus.circle"
              )
            }
          }
        }
      }
    } header: { Text("Groups") }
  }
}
