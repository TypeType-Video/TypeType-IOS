import SwiftUI

struct LiveSettingsEditingPage<Content: View>: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  let dependencies: AppDependencies
  @ViewBuilder let content: () -> Content

  var body: some View {
    List {
      content()

      if let message = viewModel.message {
        LiveSection {
          Label(message, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        }
      }
    }
      .liveGroupedList()
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        if viewModel.hasChanges {
          Button("Reset") { viewModel.resetDraft() }
        }
        Button("Save") {
          Task {
            guard let settings = await viewModel.save() else { return }
            dependencies.playbackCoordinator.applySettings(settings)
          }
        }
        .disabled(!viewModel.hasChanges || viewModel.isSaving)
        .accessibilityIdentifier("live.settings.save")
      }
    }
    .alert("Settings", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}

struct LiveSettingsAccountsView: View {
  @ObservedObject var coordinator: RootCoordinator

  var body: some View {
    List {
      LiveSection {
        ForEach(coordinator.servers) { server in
          Button {
            Task { await coordinator.selectServer(server) }
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 3) {
                Text(server.name)
                  .foregroundStyle(.primary)
                Text(server.baseURLString)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              if coordinator.selectedServer?.id == server.id {
                Image(systemName: "checkmark")
                  .foregroundStyle(.tint)
              }
            }
          }
        }

        Button("Add instance") {
          coordinator.showServerSetup()
        }
      } header: {
        Text("Instances").liveSectionHeader()
      }

      if let user = coordinator.currentUser {
        LiveSection {
          LabeledContent(
            "Username",
            value: user.publicUsername ?? "Guest"
          )
          if !user.id.hasPrefix("guest:") {
            NavigationLink("Profile") {
              LiveProfileView(coordinator: coordinator, user: user)
            }
            if coordinator.dependencies.accountProfileService != nil {
              NavigationLink("Account profiles") {
                LiveAccountProfilesView(coordinator: coordinator)
              }
            }
          }
        } header: {
        Text("Account").liveSectionHeader()
      }
      }
    }
      .liveGroupedList()
    .navigationTitle("Instances and accounts")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LiveSettingsContentView: View {
  let dependencies: AppDependencies
  @ObservedObject var viewModel: LiveSettingsViewModel

  var body: some View {
    LiveSettingsEditingPage(
      viewModel: viewModel,
      dependencies: dependencies
    ) {
      LiveSettingsDiscoverySection(
        settings: $viewModel.draft,
        services: dependencies.serviceSelection.services
      )
      LiveSection {
        Toggle("Hide Shorts", isOn: $viewModel.draft.hideShorts)
      } header: {
        Text("Visible surfaces").liveSectionHeader()
      }
    }
    .navigationTitle("Content")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LiveSettingsPrivacyView: View {
  let dependencies: AppDependencies
  @ObservedObject var viewModel: LiveSettingsViewModel

  var body: some View {
    LiveSettingsEditingPage(
      viewModel: viewModel,
      dependencies: dependencies
    ) {
      LiveSettingsPrivacySection(settings: $viewModel.draft)
      LiveSection {
        NavigationLink("Manage stored data") {
          LivePrivacyDataView(
            history: dependencies.historyService,
            searchHistory: dependencies.searchHistoryService,
            subscriptions: dependencies.subscriptionsService
          )
        }
      } header: {
        Text("Stored activity").liveSectionHeader()
      }
    }
    .navigationTitle("Privacy")
    .navigationBarTitleDisplayMode(.inline)
  }
}
