import SwiftUI

struct LiveSubscriptionFilterMenu: View {
  @ObservedObject var viewModel: LiveSubscriptionsViewModel

  var body: some View {
    Menu {
      Button {
        Task { await viewModel.selectFilter(.all) }
      } label: {
        Label("All subscriptions", systemImage: "square.grid.2x2")
      }
      Button {
        Task { await viewModel.selectFilter(.ungrouped) }
      } label: {
        Label("Ungrouped", systemImage: "tray")
      }
      Button {
        Task { await viewModel.selectFilter(.shorts) }
      } label: {
        Label("Shorts", systemImage: "play.rectangle.on.rectangle")
      }
      if !viewModel.groups.isEmpty {
        Section {
          ForEach(viewModel.groups) { group in
            Button(group.name) {
              Task {
                await viewModel.selectFilter(.group(
                  id: group.id,
                  name: group.name
                ))
              }
            }
          }
        } header: { Text("Groups") }
      }
    } label: {
      Image(systemName: "folder.badge.gearshape")
    }
    .disabled(viewModel.state != .loaded)
    .accessibilityLabel("Subscription filter")
    .accessibilityValue(viewModel.filterLabel)
    .accessibilityIdentifier("live.subscriptions.filter")
  }
}
