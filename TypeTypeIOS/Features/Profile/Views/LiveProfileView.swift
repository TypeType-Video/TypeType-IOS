import PhotosUI
import SwiftUI

struct LiveProfileView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject var viewModel: LiveProfileViewModel
  @State var selectedPhoto: PhotosPickerItem?

  init(coordinator: RootCoordinator, user: AuthUser) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: LiveProfileViewModel(
        user: user,
        service: coordinator.dependencies.profileService,
        onProfileChanged: {
          await coordinator.refreshCurrentUser()
        }
      )
    )
  }

  var body: some View {
    content
      .navigationTitle("Profile")
      .navigationBarTitleDisplayMode(.inline)
      .task { await viewModel.prepare() }
      .onChange(of: selectedPhoto) {
        guard let selectedPhoto else { return }
        Task { await importPhoto(selectedPhoto) }
      }
      .alert("Profile", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .accessibilityIdentifier("live.profile.screen")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView("Loading profile")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView {
        Label("Profile unavailable", systemImage: "person.crop.circle.badge.xmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      form
    }
  }

  private var form: some View {
    Form {
      LiveProfileAvatarSection(
        user: coordinator.currentUser,
        selectedPhoto: $selectedPhoto,
        isBusy: viewModel.isSaving,
        onEmoji: { code in
          Task { await viewModel.setEmoji(code: code) }
        },
        onClear: {
          Task { await viewModel.clearAvatar() }
        }
      )
      LiveProfileDetailsSection(viewModel: viewModel)
      Section {
        NavigationLink("Email and account name") {
          LiveAccountIdentityView(
            service: coordinator.dependencies.profileService
          )
        }
      } header: { Text("Account").liveSectionHeader() }
      if let message = viewModel.message {
        Section {
          Label(message, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        }
      }
    }
      .liveThemedList()
      .id(DemoTheme.renderToken)
  }

  private func importPhoto(_ item: PhotosPickerItem) async {
    guard let data = try? await item.loadTransferable(type: Data.self) else {
      return
    }
    let type = item.supportedContentTypes.first?.preferredMIMEType
      ?? "application/octet-stream"
    await viewModel.uploadAvatar(data: data, mediaType: type)
    selectedPhoto = nil
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
