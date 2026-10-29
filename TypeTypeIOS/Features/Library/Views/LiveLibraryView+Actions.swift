import SwiftUI

extension LiveLibraryView {
  /// The section's action, always visible at the strip's trailing edge.
  @ViewBuilder
  var sectionAction: some View {
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

  func sortMenu(
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
}
