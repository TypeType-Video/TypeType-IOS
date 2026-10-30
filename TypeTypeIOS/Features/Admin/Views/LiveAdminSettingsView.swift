import SwiftUI

struct LiveAdminSettingsView: View {
  @StateObject private var viewModel: LiveAdminSettingsViewModel

  init(service: LiveAdminServiceProtocol) {
    _viewModel = StateObject(
      wrappedValue: LiveAdminSettingsViewModel(service: service)
    )
  }

  var body: some View {
    content
      .navigationTitle("Instance settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          if viewModel.hasChanges {
            Button("Reset") { viewModel.reset() }
          }
          Button("Save") {
            Task { await viewModel.save() }
          }
          .disabled(!viewModel.hasChanges || viewModel.isSaving)
        }
      }
      .task { await viewModel.prepare() }
      .alert("Administration", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .settings, count: 8)
    case let .failed(message):
      ContentUnavailableView {
        Label("Settings unavailable", systemImage: "server.rack")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      if let value = viewModel.draft {
        LiveAdminSettingsForm(
          settings: Binding(
            get: { viewModel.draft ?? value },
            set: { viewModel.draft = $0 }
          ),
          message: viewModel.message
        )
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
