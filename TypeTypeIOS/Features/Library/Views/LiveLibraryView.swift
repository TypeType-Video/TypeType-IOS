import SwiftUI

/// The library tab's sections, switched by the segment strip.
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
  @Environment(\.themePalette) var palette
  @ObservedObject var coordinator: RootCoordinator
  @Binding var section: LiveLibrarySection
  // One model per section owned here: the strip actions act on the same
  // instance the pages render, and the sort survives browsing.
  @StateObject var historyModel: LiveHistoryViewModel
  @StateObject var favoritesModel: LiveCollectionViewModel
  @StateObject var watchLaterModel: LiveCollectionViewModel
  @State var historyConfirmsClear = false
  @State var createsPlaylist = false

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
    // An inset above the stack, so no page chrome (the History search field) slides over it.
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
