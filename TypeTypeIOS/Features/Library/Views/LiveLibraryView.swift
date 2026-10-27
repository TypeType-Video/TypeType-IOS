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
      // A horizontal swipe swaps the section with a crossfade: only one
      // section is ever on screen (the paged style showed the neighbour
      // while dragging, which read as two screens at once).
      // Instant swap: a crossfade keeps the outgoing page's toolbar items
      // in the bar during the fade, which showed both sections' controls at
      // once. Only one section exists in the hierarchy at any instant.
      ZStack {
        sectionContent(section)
          .id(section)
      }
      .simultaneousGesture(
        DragGesture(minimumDistance: 28)
          .onEnded { value in
            guard abs(value.translation.width) > 60,
              abs(value.translation.width) > abs(value.translation.height)
            else { return }
            let all = LiveLibrarySection.allCases
            guard let index = all.firstIndex(of: section) else { return }
            let next = value.translation.width < 0 ? index + 1 : index - 1
            guard all.indices.contains(next) else { return }
            section = all[next]
          }
      )
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
  private func sectionContent(
    _ section: LiveLibrarySection
  ) -> some View {
    // Single-instance switch: scroll state resets per section on purpose,
    // the paged TabView kept it only by holding every page alive.
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
      .padding(.trailing, 96)
    }
    .padding(.vertical, 4)
    .background(palette.background)
  }
}
