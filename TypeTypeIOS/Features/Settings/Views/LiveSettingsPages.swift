import SwiftUI

enum LiveSettingsScope {
  case account
  case device
  case mixed
}

struct LiveSettingsEditingPage<Content: View>: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  var scope = LiveSettingsScope.account
  @ViewBuilder let content: () -> Content

  var body: some View {
    List {
      if viewModel.isOffline, scope != .device {
        LiveSection {
          LiveSettingsOfflineNotice()
        }
      }
      if scope == .account {
        content().disabled(viewModel.isOffline)
      } else {
        content()
      }
    }
    .liveGroupedList()
    .liveSettingsSaveFailureToast(viewModel)
  }
}

struct LiveSettingsOfflineNotice: View {
  var body: some View {
    Label {
      VStack(alignment: .leading, spacing: 2) {
        Text("Offline")
          .font(.headline)
        Text("Account settings can be changed again once you are connected.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    } icon: {
      Image(systemName: "wifi.slash")
        .foregroundStyle(.orange)
    }
    .accessibilityElement(children: .combine)
  }
}

struct LiveSettingsContentView: View {
  let dependencies: AppDependencies
  @ObservedObject var viewModel: LiveSettingsViewModel

  var body: some View {
    LiveSettingsEditingPage(viewModel: viewModel) {
      LiveSettingsDiscoverySection(
        settings: $viewModel.draft,
        services: dependencies.serviceSelection.services
      )
    }
    .navigationTitle("Content")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LiveSettingsPrivacyView: View {
  let dependencies: AppDependencies
  @ObservedObject var viewModel: LiveSettingsViewModel

  var body: some View {
    LiveSettingsEditingPage(viewModel: viewModel, scope: .mixed) {
      LiveSettingsPrivacySection(settings: $viewModel.draft)
        .disabled(viewModel.isOffline)
      LiveSettingsSessionSection(service: dependencies.sessionActivityService)
      LiveSection {
        NavigationLink {
          LivePrivacyDataView(
            history: dependencies.historyService,
            searchHistory: dependencies.searchHistoryService,
            subscriptions: dependencies.subscriptionsService
          )
        } label: {
          LiveSettingText(title: "Manage stored data", detail: "Clear your history, searches or subscriptions.")
        }
      } header: {
        Text("Stored activity").liveSectionHeader()
      }
    }
    .navigationTitle("Privacy")
    .navigationBarTitleDisplayMode(.inline)
  }
}
