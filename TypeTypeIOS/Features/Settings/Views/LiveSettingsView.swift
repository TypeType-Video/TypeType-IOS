import SwiftUI

struct LiveSettingsView: View {
  @StateObject private var viewModel: LiveSettingsViewModel
  private let dependencies: AppDependencies

  init(dependencies: AppDependencies) {
    self.dependencies = dependencies
    _viewModel = StateObject(
      wrappedValue: LiveSettingsViewModel(
        service: dependencies.settingsService,
        serviceSelection: dependencies.serviceSelection,
        deArrowStore: dependencies.deArrowStore
      )
    )
  }

  var body: some View {
    content
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          if viewModel.hasChanges {
            Button("Reset") { viewModel.resetDraft() }
          }
          Button("Save") {
            Task {
              guard let settings = await viewModel.save() else {
                return
              }
              dependencies.playbackCoordinator.applySettings(settings)
            }
          }
          .disabled(!viewModel.hasChanges || viewModel.isSaving)
          .accessibilityIdentifier("live.settings.save")
        }
      }
      .task { await viewModel.prepare() }
      .alert("Settings", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .accessibilityIdentifier("live.settings.screen")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView("Loading settings")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView {
        Label("Settings unavailable", systemImage: "gear.badge.xmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      Form {
        LiveSettingsPlaybackSection(settings: $viewModel.draft)
        LiveSettingsLanguageSection(settings: $viewModel.draft)
        LiveSettingsDiscoverySection(
          settings: $viewModel.draft,
          services: dependencies.serviceSelection.services
        )
        LiveSettingsSponsorBlockSection(settings: $viewModel.draft)
        LiveSettingsPrivacySection(settings: $viewModel.draft)
        Section("Stored data") {
          NavigationLink("Manage stored data") {
            LivePrivacyDataView(
              history: dependencies.historyService,
              searchHistory: dependencies.searchHistoryService,
              subscriptions: dependencies.subscriptionsService
            )
          }
        }
        if let message = viewModel.message {
          Section {
            Label(message, systemImage: "checkmark.circle.fill")
              .foregroundStyle(.green)
          }
        }
      }
    }
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
