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
  @ObservedObject var coordinator: RootCoordinator
  @Binding var section: LiveLibrarySection
  @State private var collectionSorts: [LiveLibrarySection: LiveCollectionViewModel.Sort] = [:]

  /// Two-way bridge: the pager writes during the drag (the strip follows
  /// the finger), pill taps animate the pager to the section.
  @State private var historyConfirmsClear = false
  @State private var createsPlaylist = false

  private var collectionSortBinding: Binding<LiveCollectionViewModel.Sort> {
    Binding(
      get: { collectionSorts[section, default: .addedNewest] },
      set: { collectionSorts[section] = $0 }
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

  /// The bar items belong to the library, not to lazy pager pages: page
  /// toolbars never attach inside the pager, which is why the buttons
  /// vanished when the sections moved into it.
  @ToolbarContentBuilder
  private var sectionToolbar: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      Text(section.title)
    }
    switch section {
    case .history:
      ToolbarItem(placement: .topBarTrailing) {
        Button("Clear", role: .destructive) {
          historyConfirmsClear = true
        }
      }
    case .favorites, .watchLater:
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Picker("Sort", selection: collectionSortBinding) {
            ForEach(LiveCollectionViewModel.Sort.allCases) {
              Text($0.title).tag($0)
            }
          }
        } label: {
          Label("Sort", systemImage: "arrow.up.arrow.down")
        }
      }
    case .playlists:
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          createsPlaylist = true
        } label: {
          Image(systemName: "plus")
        }
        .accessibilityIdentifier("live.playlists.add")
      }
    case .downloads:
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          Task { await coordinator.dependencies.downloadCenter.refresh() }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
      }
    }
  }

  private var pager: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 0) {
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
        .toolbar {
          sectionToolbar
        }
    }
    // The strip sits above the stack as an inset, so no page chrome (the
    // History search field) can slide over it.
    .safeAreaInset(edge: .top, spacing: 0) {
      LiveLibrarySectionStrip(selection: $section)
        .background(DemoTheme.background)
    }
    .accessibilityIdentifier("live.library.screen")
  }

  @ViewBuilder
  private func sectionContent(
    _ section: LiveLibrarySection
  ) -> some View {
    switch section {
    case .history:
      LiveHistoryView(coordinator: coordinator)
    case .favorites:
      LiveCollectionView(
        kind: .favorites,
        dependencies: coordinator.dependencies
      )
    case .watchLater:
      LiveCollectionView(
        kind: .watchLater,
        dependencies: coordinator.dependencies
      )
    case .playlists:
      LivePlaylistsView(
        coordinator: coordinator,
        requestedCollection: .constant(nil)
      )
    case .downloads:
      LiveDownloadsView(
        center: coordinator.dependencies.downloadCenter,
        onlinePlaybackCoordinator:
          coordinator.dependencies.playbackCoordinator
      )
    }
  }
}

/// The segment strip above the library content. It reads the palette from
/// the environment: as a safe-area inset it sits outside the themed list
/// and would otherwise keep the previous theme's resolved colours.
private struct LiveLibrarySectionStrip: View {
  @Binding var selection: LiveLibrarySection
  @Environment(\.demoTheme) private var palette
  @State private var stripPosition: LiveLibrarySection?

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(LiveLibrarySection.allCases) { section in
          Button {
            withAnimation(.easeInOut(duration: 0.28)) {
              selection = section
            }
          } label: {
            Text(section.title)
              .font(.body.weight(.semibold))
              .foregroundStyle(
                section == selection ? Color.primary : Color.secondary
              )
              .padding(.horizontal, 18)
              .frame(height: 40)
              .background(
                section == selection
                  ? palette.surface
                  : Color.clear,
                in: Capsule()
              )
          }
          .buttonStyle(.plain)
          .id(section)
          .accessibilityAddTraits(
            section == selection ? [.isSelected] : []
          )
        }
      }
      .padding(.horizontal, 16)
      .padding(.trailing, 96)
      .scrollTargetLayout()
    }
    // The active pill stays centred: pager swipes flip the selection and
    // this binding scrolls the strip along instead of clipping the pill at
    // the screen edge.
    .scrollPosition(id: $stripPosition, anchor: .center)
    .scrollTargetBehavior(.viewAligned)
    .onChange(of: selection) { _, newValue in
      guard stripPosition != newValue else { return }
      withAnimation(.easeInOut(duration: 0.28)) {
        stripPosition = newValue
      }
    }
    .onAppear { stripPosition = selection }
    .padding(.vertical, 4)
    .background(palette.background)
  }
}
