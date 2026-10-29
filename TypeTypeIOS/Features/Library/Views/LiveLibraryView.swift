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
      .background(DemoTheme.background)
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
        viewModel: historyModel
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

/// The segment strip above the library content. It reads the palette from
/// the environment: as a safe-area inset it sits outside the themed list
/// and would otherwise keep the previous theme's resolved colours.
/// The action tile's shell: system Liquid Glass where available, the
/// grouped surface colour otherwise.
struct LiveLibraryActionGlass: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.glassEffect()
    } else {
      content.background(
        DemoTheme.groupedSurface,
        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
    }
  }
}

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

/// The library's tab-strip selection, exposed to pushed pages as a value
/// plus its binding: a horizontal swipe there switches tabs, and any page
/// steps aside when the selection moves on (swipe or strip tap).
struct LiveLibrarySectionContext: Equatable {
  let value: LiveLibrarySection
  let binding: Binding<LiveLibrarySection>

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.value == rhs.value
  }
}

private struct LiveLibrarySectionContextKey: EnvironmentKey {
  static let defaultValue: LiveLibrarySectionContext? = nil
}

extension EnvironmentValues {
  var librarySectionContext: LiveLibrarySectionContext? {
    get { self[LiveLibrarySectionContextKey.self] }
    set { self[LiveLibrarySectionContextKey.self] = newValue }
  }
}

/// A pushed library page: a horizontal swipe switches the tab strip to the
/// neighboring section, and the page dismisses once the selection moved on.
struct LiveLibrarySectionSwipe: ViewModifier {
  @Environment(\.librarySectionContext) private var section
  @Environment(\.dismiss) private var dismiss
  @State private var homeSection: LiveLibrarySection?

  func body(content: Content) -> some View {
    content
      .onAppear {
        homeSection = section?.value
      }
      .onChange(of: section?.value) { _, newValue in
        guard let homeSection, let newValue, newValue != homeSection else {
          return
        }
        dismiss()
      }
      .simultaneousGesture(
        DragGesture(minimumDistance: 28)
          .onEnded { value in
            guard abs(value.translation.width)
              > abs(value.translation.height) * 1.25,
              let homeSection,
              let index = LiveLibrarySection.allCases.firstIndex(of: homeSection)
            else { return }
            let target = index + (value.translation.width < 0 ? 1 : -1)
            guard LiveLibrarySection.allCases.indices.contains(target) else {
              return
            }
            section?.binding.wrappedValue = LiveLibrarySection.allCases[target]
          }
      )
  }
}

extension View {
  func liveLibrarySectionSwipe() -> some View {
    modifier(LiveLibrarySectionSwipe())
  }
}
