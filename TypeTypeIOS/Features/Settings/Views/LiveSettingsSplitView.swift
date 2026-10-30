import SwiftUI

struct LiveSettingsSplitView: View {
  @StateObject private var viewModel: LiveSettingsViewModel
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject private var preferences: LiveAppPreferencesStore
  @State private var selection: LiveSettingsPage? = .appearance
  @Environment(\.dismiss) private var dismiss
  @Environment(\.themePalette) private var palette
  @Environment(\.horizontalSizeClass) private var sizeClass

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _preferences = ObservedObject(wrappedValue: coordinator.dependencies.appPreferences)
    _viewModel = StateObject(wrappedValue: LiveSettingsView.makeViewModel(for: coordinator))
  }

  var body: some View {
    Group {
      if sizeClass == .compact {
        NavigationStack {
          LiveSettingsView(coordinator: coordinator)
            .toolbar { doneButton }
        }
      } else {
        NavigationSplitView {
          sidebar
        } detail: {
          NavigationStack { detail }
        }
      }
    }
    .tint(preferences.preferences.accent)
    .task { await viewModel.prepare() }
    .accessibilityIdentifier("live.settings.split")
  }

  private var sidebar: some View {
    List {
      LiveSection {
        sidebarRow(.accounts) { LiveSettingsAccountSummary(coordinator: coordinator) }
      }
      ForEach(Array(coordinator.settingsGroups.enumerated()), id: \.offset) { _, pages in
        LiveSection {
          ForEach(pages) { page in
            sidebarRow(page) {
              LiveSettingsPageLabel(page: page, downloads: coordinator.dependencies.downloadCenter)
            }
          }
        }
      }
    }
    .liveGroupedList()
    .navigationTitle("Settings")
    .toolbar { doneButton }
  }

  private func sidebarRow(_ page: LiveSettingsPage, @ViewBuilder label: () -> some View) -> some View {
    Button { selection = page } label: { label() }
      .tint(Color.primary)
      .listRowBackground(rowBackground(page))
      .accessibilityAddTraits(selection == page ? .isSelected : [])
  }

  private var doneButton: some ToolbarContent {
    ToolbarItem(placement: .confirmationAction) {
      Button("Done") { dismiss() }
    }
  }

  private func rowBackground(_ page: LiveSettingsPage) -> Color {
    selection == page ? palette.accent.opacity(0.16) : palette.rowBackground
  }

  @ViewBuilder
  private var detail: some View {
    switch (viewModel.state, selection) {
    case (.loaded, let page?):
      LiveSettingsDestination(page: page, coordinator: coordinator, viewModel: viewModel, preferences: preferences)
        .id(page)
    case (.failed(let message), _):
      ContentUnavailableView {
        Label("Settings unavailable", systemImage: "gear.badge.xmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") { Task { await viewModel.reload() } }
      }
    case (.loaded, nil):
      ContentUnavailableView("Choose a setting", systemImage: "gearshape")
    default:
      ProgressView()
    }
  }
}

struct LiveSettingsEntry<Label: View>: View {
  @ObservedObject var coordinator: RootCoordinator
  @ViewBuilder let label: () -> Label
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    if sizeClass == .regular {
      Button { coordinator.presentsSettings = true } label: { label() }
    } else {
      NavigationLink {
        LiveSettingsView(coordinator: coordinator)
      } label: {
        label()
      }
    }
  }
}

struct LiveSettingsPresentation: ViewModifier {
  @ObservedObject var coordinator: RootCoordinator

  func body(content: Content) -> some View {
    if #available(iOS 18.0, *) {
      content.sheet(isPresented: $coordinator.presentsSettings) {
        LiveSettingsSplitView(coordinator: coordinator)
          .presentationSizing(.page)
      }
    } else {
      content.fullScreenCover(isPresented: $coordinator.presentsSettings) {
        LiveSettingsSplitView(coordinator: coordinator)
      }
    }
  }
}
