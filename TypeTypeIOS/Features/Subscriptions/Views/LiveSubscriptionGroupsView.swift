import SwiftUI

struct LiveSubscriptionGroupsView: View {
  @StateObject private var viewModel: LiveSubscriptionGroupsViewModel
  @State private var isCreating = false
  @State private var newGroupName = ""
  @State private var renamingGroup: LiveSubscriptionGroup?
  @State private var renameText = ""
  @State private var deletingGroup: LiveSubscriptionGroup?

  init(viewModel: LiveSubscriptionsViewModel) {
    _viewModel = StateObject(wrappedValue: .init(source: viewModel))
  }

  var body: some View {
    List {
      newGroupSection
      groupsSection
      if viewModel.hasChannels {
        channelsSection
      }
    }
      .liveThemedList()
      .id(DemoTheme.renderToken)
      .listStyle(.insetGrouped)
    .navigationTitle("Groups")
    .navigationBarTitleDisplayMode(.inline)
    .overlay {
      if viewModel.isRefreshing, viewModel.groups.isEmpty {
        ProgressView("Loading groups")
      }
    }
    .refreshable {
      await viewModel.refresh()
    }
    .task {
      await viewModel.refresh()
    }
    .alert(
      "New group",
      isPresented: Binding(
        get: { isCreating },
        set: { visible in
          isCreating = visible
          if !visible { newGroupName = "" }
        }
      )
    ) {
      TextField("Name", text: $newGroupName)
      Button("Cancel", role: .cancel) {}
      Button("Create") {
        let name = newGroupName.trimmingCharacters(
          in: .whitespacesAndNewlines
        )
        guard !name.isEmpty else { return }
        Task { await viewModel.createGroup(named: name) }
      }
    } message: {
      Text("Group names can contain up to 100 characters.")
    }
    .alert(
      "Rename group",
      isPresented: Binding(
        get: { renamingGroup != nil },
        set: { visible in
          if !visible { renamingGroup = nil }
        }
      )
    ) {
      TextField("Name", text: $renameText)
      Button("Cancel", role: .cancel) { renamingGroup = nil }
      Button("Rename") {
        guard let group = renamingGroup else { return }
        let name = renameText.trimmingCharacters(
          in: .whitespacesAndNewlines
        )
        guard !name.isEmpty else { return }
        Task { await viewModel.renameGroup(group, to: name) }
      }
    }
    .alert(
      "Delete group",
      isPresented: Binding(
        get: { deletingGroup != nil },
        set: { visible in
          if !visible { deletingGroup = nil }
        }
      ),
      presenting: deletingGroup
    ) { group in
      Button("Delete", role: .destructive) {
        Task { await viewModel.deleteGroup(group) }
      }
      Button("Cancel", role: .cancel) {}
    } message: { group in
      Text(
        "Delete “\(group.name)”? Channels will remain subscribed and become ungrouped."
      )
    }
    .alert(
      "Group unavailable",
      isPresented: Binding(
        get: { viewModel.errorMessage != nil },
        set: { visible in
          if !visible { viewModel.errorMessage = nil }
        }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .accessibilityIdentifier("live.subscription-groups.screen")
  }

  @ViewBuilder
  private var newGroupSection: some View {
    Section {
      TextField("Group name", text: $newGroupName)
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
        .onSubmit(createGroup)
      Button {
        createGroup()
      } label: {
        if viewModel.isMutating {
          ProgressView()
        } else {
          Label("Create group", systemImage: "plus")
        }
      }
      .disabled(
        viewModel.isMutating
          || newGroupName.trimmingCharacters(
            in: .whitespacesAndNewlines
          ).isEmpty
      )
    } header: { Text("Create group").liveSectionHeader() }
  }

  @ViewBuilder
  private var groupsSection: some View {
    Section {
      if viewModel.sortedGroups.isEmpty {
        Text("No groups yet")
          .foregroundStyle(.secondary)
      } else {
        ForEach(viewModel.sortedGroups) { group in
          groupRow(group)
        }
      }
    } header: { Text("Groups").liveSectionHeader() }
  }

  @ViewBuilder
  private var channelsSection: some View {
    Section {
      ForEach(viewModel.channels) { channel in
        channelRow(channel)
      }
    } header: { Text("Channels").liveSectionHeader() }
  }

  private func groupRow(
    _ group: LiveSubscriptionGroup
  ) -> some View {
    HStack(spacing: 12) {
      Image(systemName: "folder.fill")
        .foregroundStyle(DemoTheme.accent)
      VStack(alignment: .leading, spacing: 3) {
        Text(group.name)
          .font(.body.weight(.semibold))
          .lineLimit(1)
        Text(
          group.channelCount == 1
            ? "1 channel"
            : "\(group.channelCount) channels"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      Spacer()
      Menu {
        Button {
          renameText = group.name
          renamingGroup = group
        } label: {
          Label("Rename", systemImage: "pencil")
        }
        Button(role: .destructive) {
          deletingGroup = group
        } label: {
          Label("Delete", systemImage: "trash")
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.body)
          .foregroundStyle(.secondary)
      }
      .accessibilityLabel("Group actions for \(group.name)")
    }
    .padding(.vertical, 2)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(group.name), \(group.channelCount) channels")
  }

  private func channelRow(
    _ channel: LiveSubscription
  ) -> some View {
    let memberIDs = viewModel.groupIDs(for: channel)
    return HStack(spacing: 12) {
      LiveRemoteImage(url: URL(string: channel.avatarURL))
        .frame(width: 42, height: 42)
        .clipShape(Circle())
      VStack(alignment: .leading, spacing: 3) {
        Text(channel.name)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
        Text(membershipSummary(memberIDs))
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      Spacer()
      Menu {
        Section {
          ForEach(viewModel.sortedGroups) { group in
            let isMember = memberIDs.contains(group.id)
            Button {
              Task {
                await viewModel.toggleMembership(channel, in: group)
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
        } header: { Text("Groups").liveSectionHeader() }
      } label: {
        Image(systemName: "rectangle.stack.badge.plus")
          .font(.body)
      }
      .accessibilityLabel("Manage groups for \(channel.name)")
      .disabled(viewModel.isMutating)
    }
    .padding(.vertical, 2)
    .accessibilityElement(children: .combine)
  }

  private func membershipSummary(
    _ groupIDs: Set<String>
  ) -> String {
    let names = viewModel.sortedGroups
      .filter { groupIDs.contains($0.id) }
      .map(\.name)
    guard !names.isEmpty else { return "Ungrouped" }
    return names.joined(separator: ", ")
  }

  private func createGroup() {
    let name = newGroupName.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard !name.isEmpty else { return }
    Task {
      await viewModel.createGroup(named: name)
      if viewModel.errorMessage == nil {
        newGroupName = ""
      }
    }
  }
}
