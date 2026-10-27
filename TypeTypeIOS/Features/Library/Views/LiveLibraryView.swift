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

  var body: some View {
    NavigationStack {
      // One paged container per section: horizontal swipes move between the
      // strip's sections (auto-animated, index-bound to the strip), each
      // page keeps its own scroll state while the strip stays pinned.
      TabView(selection: $section) {
        ForEach(LiveLibrarySection.allCases) { section in
          sectionContent
            .id(section)
            .navigationBarTitleDisplayMode(.inline)
            .tag(section)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .onChange(of: section) { _, _ in }
      .toolbar {
        ToolbarItem(placement: .principal) {
          LiveLibrarySectionStrip(selection: $section)
            .background(DemoTheme.background)
            .accessibilityIdentifier("live.library.sections")
        }
      }
    }
    .accessibilityIdentifier("live.library.screen")
  }

  @ViewBuilder
  private var sectionContent: some View {
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

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(LiveLibrarySection.allCases) { section in
          Button {
            selection = section
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
          .accessibilityAddTraits(
            section == selection ? [.isSelected] : []
          )
        }
      }
      .padding(.horizontal, 16)
    }
    .padding(.vertical, 4)
    .background(palette.background)
  }
}
