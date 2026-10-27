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
      sectionContent
        .id(section)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
          LiveLibrarySectionStrip(selection: $section)
            .background(DemoTheme.background)
            .accessibilityIdentifier("live.library.sections")
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

/// The segment strip above the library content, drawn with the app's own
/// theme colours (no beta design tokens needed).
private struct LiveLibrarySectionStrip: View {
  @Binding var selection: LiveLibrarySection

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(LiveLibrarySection.allCases) { section in
          Button {
            selection = section
          } label: {
            Text(section.title)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(
                section == selection ? Color.primary : Color.secondary
              )
              .padding(.horizontal, 14)
              .frame(height: 32)
              .background(
                section == selection
                  ? DemoTheme.groupedSurface
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
  }
}
