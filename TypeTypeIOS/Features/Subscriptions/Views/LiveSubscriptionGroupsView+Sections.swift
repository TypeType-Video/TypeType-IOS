import SwiftUI

extension LiveSubscriptionGroupsView {
  @ViewBuilder
  var newGroupSection: some View {
    LiveSection {
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
  var groupsSection: some View {
    LiveSection {
      if viewModel.isRefreshing, viewModel.groups.isEmpty {
        TypeTypeSkeletonRows(leading: .rectangle(width: 22, height: 22), count: 3)
      } else if viewModel.sortedGroups.isEmpty {
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
  var channelsSection: some View {
    LiveSection {
      ForEach(viewModel.channels) { channel in
        channelRow(channel)
      }
    } header: { Text("Channels").liveSectionHeader() }
  }

  func groupRow(_ group: LiveSubscriptionGroup) -> some View {
    HStack(spacing: 12) {
      Image(systemName: "folder.fill")
        .foregroundStyle(palette.accent)
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

  func channelRow(_ channel: LiveSubscription) -> some View {
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
        } header: { Text("Groups") }
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

  func membershipSummary(_ groupIDs: Set<String>) -> String {
    let names = viewModel.sortedGroups
      .filter { groupIDs.contains($0.id) }
      .map(\.name)
    guard !names.isEmpty else { return "Ungrouped" }
    return names.joined(separator: ", ")
  }

  func createGroup() {
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
