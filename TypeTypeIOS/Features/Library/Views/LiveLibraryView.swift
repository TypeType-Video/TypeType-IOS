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

  var body: some View {
    NavigationStack {
      ScrollView(.horizontal) {
        LazyHStack(spacing: 0) {
          ForEach(LiveLibrarySection.allCases) { page in
            sectionContent(page)
              .navigationBarTitleDisplayMode(.inline)
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
