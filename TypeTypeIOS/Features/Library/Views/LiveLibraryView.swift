import SwiftUI

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

  var systemImage: String {
    switch self {
    case .history: return "clock.arrow.circlepath"
    case .favorites: return "heart"
    case .watchLater: return "clock"
    case .playlists: return "rectangle.stack"
    case .downloads: return "arrow.down.circle"
    }
  }
}

struct LiveLibraryView: View {
  @Environment(\.themePalette) var palette
  @Environment(\.horizontalSizeClass) private var sizeClass
  @ObservedObject var coordinator: RootCoordinator
  @Binding var section: LiveLibrarySection
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
        service: coordinator.dependencies.historyService,
        watchProgress: coordinator.dependencies.watchProgress
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
    Group {
      if sizeClass == .regular {
        splitLayout
      } else {
        pagedLayout
      }
    }
    .accessibilityIdentifier("live.library.screen")
  }

  private var pagedLayout: some View {
    NavigationStack {
      pager
    }
    .environment(
      \.librarySectionContext,
      LiveLibrarySectionContext(value: section, binding: $section)
    )
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
  }

  @ViewBuilder
  func sectionContent(
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
        center: coordinator.dependencies.downloadCenter
      )
    }
  }
}
