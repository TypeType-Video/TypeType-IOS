import SwiftUI

struct LiveYouTubeSessionView: View {
  @StateObject private var viewModel: LiveYouTubeSessionViewModel
  @State private var confirmsDisconnect = false

  init(coordinator: RootCoordinator, service: LiveYouTubeSessionServiceProtocol) {
    let dependencies = coordinator.dependencies
    let serverID = coordinator.selectedServer?.id
    _viewModel = StateObject(
      wrappedValue: LiveYouTubeSessionViewModel(
        service: service,
        instanceURL: { coordinator.selectedServer?.baseURL },
        accessToken: { serverID.flatMap { dependencies.sessionStore.accessToken(forServerID: $0) } }
      )
    )
  }

  var body: some View {
    List {
      if let browser = viewModel.browser {
        LiveSection {
          LiveYouTubeBrowserPane(
            browser: browser,
            onCancel: { Task { await viewModel.cancel() } },
            onFinished: { Task { await viewModel.browserFinished() } }
          )
        }
      } else {
        statusSection
      }
    }
    .liveGroupedList()
    .navigationTitle("YouTube sign-in")
    .navigationBarTitleDisplayMode(.inline)
    .task { await viewModel.refresh() }
    .alert("YouTube sign-in", isPresented: errorBinding) {
      Button("OK") { viewModel.errorMessage = nil }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .alert("Disconnect YouTube?", isPresented: $confirmsDisconnect) {
      Button("Disconnect", role: .destructive) { Task { await viewModel.disconnect() } }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("TypeType will stop using the session stored for this account.")
    }
  }

  @ViewBuilder
  private var statusSection: some View {
    switch viewModel.state {
    case .loading:
      LiveSection { ProgressView().frame(maxWidth: .infinity) }
    case let .failed(message):
      LiveSection {
        Text(message).foregroundStyle(.secondary)
        Button("Try again") { Task { await viewModel.refresh() } }
      }
    case let .loaded(status):
      LiveSection {
        Label {
          LiveSettingText(
            title: status.isConnected ? "Connected" : "Not connected",
            detail: status.isConnected
              ? "TypeType uses this session when a video needs it."
              : "Some videos need a signed-in YouTube session to play."
          )
        } icon: {
          Image(systemName: status.isConnected ? "checkmark.seal.fill" : "person.crop.circle.badge.questionmark")
            .foregroundStyle(status.isConnected ? Color.green : Color.secondary)
        }
        if status.isConnected, status.lastUsedAt > 0 {
          LabeledContent("Last used") {
            Text(Date(timeIntervalSince1970: TimeInterval(status.lastUsedAt) / 1_000), style: .relative)
          }
        }
      }
      LiveSection {
        if status.isConnected {
          Button("Disconnect", role: .destructive) { confirmsDisconnect = true }
            .disabled(viewModel.isWorking)
        } else {
          Button {
            Task { await viewModel.connect() }
          } label: {
            HStack {
              Text("Connect with YouTube")
              Spacer()
              if viewModel.isWorking { ProgressView() }
            }
          }
          .disabled(viewModel.isWorking)
        }
      } footer: {
        Text("TypeType opens a temporary browser on your instance. Sign in there; the browser then closes and your instance keeps the session. A secondary YouTube account is recommended.")
          .liveSettingsFooter()
      }
    }
  }

  private var errorBinding: Binding<Bool> {
    Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
  }
}
