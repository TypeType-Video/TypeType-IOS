import SwiftUI

struct LiveAccountProfilesView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: LiveAccountProfilesViewModel
  @State private var renamingProfile: AccountProfileItem?
  @State private var renameText = ""
  @State private var isSwitching = false
  @State private var switchError: String?

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: LiveAccountProfilesViewModel(
        service: coordinator.dependencies.accountProfileService!
      )
    )
  }

  var body: some View {
    List {
      if viewModel.isUnavailable {
        ContentUnavailableView(
          "Profiles unavailable",
          systemImage: "person.2.slash",
          description: Text("This instance does not offer account profiles.")
        )
        .listRowBackground(Color.clear)
      } else if let profiles = viewModel.profiles {
        LiveSection {
          ForEach(profiles.profiles) { profile in
            LiveAccountProfileRow(
              profile: profile,
              isSwitching: isSwitching,
              onSwitch: { Task { await switchProfile(profile) } },
              onSetDefault: { Task { await viewModel.setDefault(profile) } },
              onRename: {
                renameText = profile.name
                renamingProfile = profile
              },
              onDelete: { Task { await viewModel.delete(profile) } }
            )
          }
        } header: { Text("Profiles").liveSectionHeader() }
      } else if viewModel.errorMessage == nil {
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
        .listRowBackground(Color.clear)
      }

      if !viewModel.isUnavailable {
        LiveSection {
          TextField("Name", text: $viewModel.newName)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .onSubmit {
              Task { await viewModel.create() }
            }
          Button {
            Task { await viewModel.create() }
          } label: {
            if viewModel.isBusy {
              ProgressView()
            } else {
              Label("Create profile", systemImage: "plus")
            }
          }
          .disabled(
            viewModel.isBusy
              || viewModel.newName.trimmingCharacters(
                in: .whitespacesAndNewlines
              ).isEmpty
          )
        } header: { Text("New profile").liveSectionHeader() }
      }
    }
    .liveGroupedList()
    .navigationTitle("Profiles")
    .overlay(alignment: .bottom) {
      if let error = viewModel.errorMessage ?? switchError {
        Text(error)
          .font(.footnote.weight(.medium))
          .foregroundStyle(.white)
          .padding(.horizontal, 14)
          .padding(.vertical, 9)
          .background(.red.opacity(0.92), in: Capsule())
          .padding(.bottom, 18)
          .accessibilityIdentifier("account-profiles.error")
      }
    }
    .task {
      await viewModel.load()
    }
    .refreshable {
      await viewModel.load()
    }
    .alert(
      "Rename profile",
      isPresented: Binding(
        get: { renamingProfile != nil },
        set: { visible in
          if !visible { renamingProfile = nil }
        }
      )
    ) {
      TextField("Name", text: $renameText)
      Button("Cancel", role: .cancel) {
        renamingProfile = nil
      }
      Button("Rename") {
        guard let profile = renamingProfile else { return }
        let name = renameText.trimmingCharacters(
          in: .whitespacesAndNewlines
        )
        guard !name.isEmpty else { return }
        Task {
          await viewModel.rename(profile, to: name)
          renamingProfile = nil
        }
      }
    } message: {
      Text("Choose a name between 1 and 40 characters.")
    }
    .accessibilityIdentifier("live.account-profiles.screen")
  }

  private func switchProfile(_ profile: AccountProfileItem) async {
    guard !profile.isActive, !isSwitching else { return }
    isSwitching = true
    switchError = nil
    do {
      try await coordinator.switchAccountProfile(to: profile.id)
    } catch {
      switchError = error.localizedDescription
    }
    await viewModel.load()
    isSwitching = false
  }
}
