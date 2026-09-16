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
      if let profiles = viewModel.profiles {
        ForEach(profiles.profiles) { profile in
          row(profile)
        }
      } else if viewModel.errorMessage == nil {
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
      }

      Section("New profile") {
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
      }
    }
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

  @ViewBuilder
  private func row(_ profile: AccountProfileItem) -> some View {
    HStack(spacing: 12) {
      Image(systemName: profile.isActive ? "checkmark.circle.fill" : "person.crop.circle")
        .font(.title3)
        .foregroundStyle(profile.isActive ? Color.accentColor : .secondary)
      VStack(alignment: .leading, spacing: 3) {
        Text(profile.name)
          .font(.body.weight(.semibold))
        HStack(spacing: 6) {
          if profile.isDefault {
            Text("Default")
              .font(.caption.weight(.semibold))
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(.quaternary, in: Capsule())
          }
          if profile.isActive {
            Text("Active")
              .font(.caption.weight(.semibold))
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.accentColor.opacity(0.16), in: Capsule())
          }
        }
      }
      Spacer()
      if isSwitching && !profile.isActive {
        ProgressView()
      }
    }
    .padding(.vertical, 2)
    .contentShape(Rectangle())
    .onTapGesture {
      Task { await switchProfile(profile) }
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      if !profile.isActive {
        Button(role: .destructive) {
          Task { await viewModel.delete(profile) }
        } label: {
          Label("Delete", systemImage: "trash")
        }
      }
      Button {
        Task { await viewModel.setDefault(profile) }
      } label: {
        Label("Default", systemImage: "star")
      }
      .tint(.orange)
      Button {
        renameText = profile.name
        renamingProfile = profile
      } label: {
        Label("Rename", systemImage: "pencil")
      }
      .tint(.blue)
    }
    .contextMenu {
      if !profile.isActive {
        Button {
          Task { await switchProfile(profile) }
        } label: {
          Label("Switch to profile", systemImage: "arrow.left.arrow.right.circle")
        }
      }
      Button {
        Task { await viewModel.setDefault(profile) }
      } label: {
        Label("Set as default", systemImage: "star")
      }
      Button {
        renameText = profile.name
        renamingProfile = profile
      } label: {
        Label("Rename", systemImage: "pencil")
      }
      if !profile.isActive {
        Button(role: .destructive) {
          Task { await viewModel.delete(profile) }
        } label: {
          Label("Delete profile", systemImage: "trash")
        }
      }
    }
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
