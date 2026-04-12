import SwiftUI

struct SettingsView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: SettingsViewModel

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: SettingsViewModel(service: coordinator.dependencies.userSettingsService)
    )
  }

  @ViewBuilder
  private var statusMessages: some View {
    if let errorMessage = viewModel.errorMessage {
      Text(errorMessage)
        .font(.footnote)
        .foregroundStyle(.red)
    }
    if let infoMessage = viewModel.infoMessage {
      Text(infoMessage)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        if let selected = coordinator.selectedServer {
          Section("Current Server") {
            Text(selected.name)
            Text(selected.baseURLString)
              .font(.footnote)
              .foregroundStyle(.secondary)
            Button("Manage Servers") {
              coordinator.state = .serverSetup
            }
          }
        }

        if let session = coordinator.currentSession {
          Section("Session") {
            LabeledContent("Email", value: session.userEmail)
            LabeledContent("Role", value: session.role)
            NavigationLink("Edit Profile") {
              ProfileView(coordinator: coordinator)
            }
            NavigationLink("Reset Password") {
              ResetPasswordView(service: coordinator.dependencies.resetPasswordService)
            }
            NavigationLink("Import from YouTube") {
              YoutubeImportView(service: coordinator.dependencies.youtubeImportService)
            }
            NavigationLink("Import from PipePipe") {
              PipePipeImportView(service: coordinator.dependencies.pipePipeImportService)
            }
          }
        }

        Section("Playback") {
          TextField("Default quality", text: $viewModel.draft.defaultQuality)
          Toggle("Autoplay", isOn: $viewModel.draft.autoplay)
          Toggle("Muted", isOn: $viewModel.draft.muted)
          Toggle("Subtitles enabled", isOn: $viewModel.draft.subtitlesEnabled)
          HStack {
            Text("Volume")
            Slider(value: $viewModel.draft.volume, in: 0...1)
          }
        }

        Section("Languages") {
          TextField("Subtitle language", text: $viewModel.draft.defaultSubtitleLanguage)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
          TextField("Audio language", text: $viewModel.draft.defaultAudioLanguage)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
          Toggle("Prefer original language", isOn: $viewModel.draft.preferOriginalLanguage)
        }

        Section("Discovery") {
          Stepper("Default service: \(viewModel.draft.defaultService)", value: $viewModel.draft.defaultService, in: 0...9)
          Toggle(
            "Recommendation personalization",
            isOn: $viewModel.draft.recommendationPersonalizationEnabled
          )
        }

        statusMessages

        Section {
          Button(viewModel.isSaving ? "Saving..." : "Save settings") {
            Task { await viewModel.save() }
          }
          .disabled(viewModel.isSaving || viewModel.isLoading)

          Button("Sign Out", role: .destructive) {
            coordinator.signOut()
          }
        }
      }
      .navigationTitle("Settings")
      .task {
        await viewModel.load()
      }
      .refreshable {
        await viewModel.load()
      }
    }
  }
}
