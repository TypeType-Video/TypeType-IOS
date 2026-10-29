import SwiftUI

/// The library tab: one page with a segment strip like beta — history,
/// personal collections, playlists, and downloads. The old History and
/// Playlists tabs fold into these sections.
enum LiveLibrarySection: String, CaseIterable, Identifiable {
  case history, favorites, watchLater, playlists, downloads

  var id: String { rawValue }

  var title: LocalizedStringKey {
    switch self {
    case .history: return "History"
    case .favorites: return "Favorites"
    case .watchLater: return "Watch later"
    case .playlists: return "Playlists"
    case .downloads: return "Downloads"
    }
  }
}

struct LiveLibraryView: View {
  @Environment(\.themePalette) private var palette
  @ObservedObject var coordinator: RootCoordinator
  @Binding var section: LiveLibrarySection
  // One model per section owned here: the strip actions act on the same
  // instance the pages render, and the sort survives browsing.
  @StateObject private var historyModel: LiveHistoryViewModel
  @StateObject private var favoritesModel: LiveCollectionViewModel
  @StateObject private var watchLaterModel: LiveCollectionViewModel
  @State private var historyConfirmsClear = false
  @State private var createsPlaylist = false

  init(coordinator: RootCoordinator, section: Binding<LiveLibrarySection>) {
    self.coordinator = coordinator
    _section = section
    _historyModel = StateObject(
      wrappedValue: LiveHistoryViewModel(
        service: coordinator.dependencies.historyService
      )
    )
    _favoritesModel = StateObject(
      wrappedValue: LiveCollectionViewModel(
        kind: .favorites,
        service: coordinator.dependencies.libraryService
      )
    )
    _watchLaterModel = StateObject(
      wrappedValue: LiveCollectionViewModel(
        kind: .watchLater,
        service: coordinator.dependencies.libraryService
      )
    )
  }

  /// Two-way bridge: the pager writes during the drag (the strip follows
  /// the finger), pill taps animate the pager to the section.
  private var sectionIDBinding: Binding<LiveLibrarySection?> {
    Binding(
      get: { $section.wrappedValue },
      set: { newValue in
        if let newValue { $section.wrappedValue = newValue }
      }
    )
  }

  private var pager: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 0) {
        ForEach(LiveLibrarySection.allCases) { page in
          sectionContent(page)
            .containerRelativeFrame(.horizontal)
            .id(page)
        }
      }
      .scrollTargetLayout()
    }
    .scrollPosition(id: sectionIDBinding)
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
  }

  var body: some View {
    NavigationStack {
      pager
    }
    .environment(
      \.librarySectionContext,
      LiveLibrarySectionContext(value: section, binding: $section)
    )
    // The strip sits above the stack as an inset, so no page chrome (the
    // History search field) can slide over it. The section's action rides
    // in the same row — plain SwiftUI, no bar machinery that the pager
    // could hide.
    .safeAreaInset(edge: .top, spacing: 0) {
      HStack(spacing: 6) {
        LiveLibrarySectionStrip(selection: $section)
        sectionAction
          .frame(width: 48, height: 44)
          .font(.title3.weight(.semibold))
          .foregroundStyle(Color.primary)
          .modifier(LiveLibraryActionGlass())
      }
      .padding(.horizontal, 16)
      .background(palette.background)
    }
    .accessibilityIdentifier("live.library.screen")
  }

  /// The section's action, always visible at the strip's trailing edge.
  @ViewBuilder
  private var sectionAction: some View {
    switch section {
    case .history:
      Button {
        historyConfirmsClear = true
      } label: {
        Image(systemName: "trash")
      }
      .foregroundStyle(.red)
      .disabled(historyModel.items.isEmpty)
      .accessibilityLabel("Clear history")
      .popover(
        isPresented: $historyConfirmsClear,
        attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
        arrowEdge: .top
      ) {
        LiveConfirmCard(
          title: "Clear watch history?",
          message: "This removes every video from your watch history.",
          confirmTitle: "Clear all"
        ) {
          Task { await historyModel.clear() }
        }
      }
    case .favorites:
      sortMenu(for: favoritesModel)
    case .watchLater:
      sortMenu(for: watchLaterModel)
    case .playlists:
      Button {
        createsPlaylist = true
      } label: {
        Image(systemName: "plus")
      }
      .accessibilityLabel("New playlist")
      .accessibilityIdentifier("live.playlists.add")
    case .downloads:
      Button {
        Task { await coordinator.dependencies.downloadCenter.refresh() }
      } label: {
        Image(systemName: "arrow.clockwise")
      }
      .accessibilityLabel("Refresh downloads")
    }
  }

  private func sortMenu(
    for model: LiveCollectionViewModel
  ) -> some View {
    Menu {
      Picker(
        "Sort",
        selection: Binding(
          get: { model.sort },
          set: { model.sort = $0 }
        )
      ) {
        ForEach(LiveCollectionViewModel.Sort.allCases) { order in
          Text(order.title).tag(order)
        }
      }
    } label: {
      Image(systemName: "arrow.up.arrow.down")
    }
    .disabled(model.videos.isEmpty)
    .accessibilityLabel("Sort")
  }

  @ViewBuilder
  private func sectionContent(
    _ section: LiveLibrarySection
  ) -> some View {
    switch section {
    case .history:
      LiveHistoryView(
        coordinator: coordinator,
        viewModel: historyModel,
        isActive: self.section == .history
      )
    case .favorites:
      LiveCollectionView(
        viewModel: favoritesModel,
        dependencies: coordinator.dependencies
      )
    case .watchLater:
      LiveCollectionView(
        viewModel: watchLaterModel,
        dependencies: coordinator.dependencies
      )
    case .playlists:
      LivePlaylistsView(
        coordinator: coordinator,
        requestedCollection: .constant(nil),
        createsPlaylist: $createsPlaylist
      )
    case .downloads:
      LiveDownloadsView(
        dependencies: coordinator.dependencies,
        center: coordinator.dependencies.downloadCenter,
        onlinePlaybackCoordinator:
          coordinator.dependencies.playbackCoordinator
      )
    }
  }
}
