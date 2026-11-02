import SwiftUI

struct LiveSubscriptionGroupsView: View {
  @Environment(\.themePalette) var palette
  @StateObject var viewModel: LiveSubscriptionGroupsViewModel
  @State private var isCreating = false
  @State var newGroupName = ""
  @State var renamingGroup: LiveSubscriptionGroup?
  @State var renameText = ""
  @State var deletingGroup: LiveSubscriptionGroup?

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
    .liveGroupedList()
    .navigationTitle("Groups")
    .navigationBarTitleDisplayMode(.inline)
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
}
