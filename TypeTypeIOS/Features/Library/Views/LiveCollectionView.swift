import SwiftUI

struct LiveCollectionView: View {
  let dependencies: AppDependencies
  @ObservedObject var viewModel: LiveCollectionViewModel
  @State private var selectedVideo: LiveVideoItem?
  @State private var selectedChannelURL: String?
  @State private var pendingRemoval: LiveLibraryVideo?

  /// The library owns one view model per kind so its strip actions reach
  /// the same instance the page renders; standalone uses create their own.
  init(
    kind: LiveLibraryCollectionKind,
    dependencies: AppDependencies
  ) {
    self.dependencies = dependencies
    _viewModel = ObservedObject(
      wrappedValue: LiveCollectionViewModel(
        kind: kind,
        service: dependencies.libraryService
      )
    )
  }

  init(
    viewModel: LiveCollectionViewModel,
    dependencies: AppDependencies
  ) {
    self.dependencies = dependencies
    _viewModel = ObservedObject(wrappedValue: viewModel)
  }

  var body: some View {
    content
      .liveLibrarySectionSwipe()
      .navigationTitle(viewModel.kind.title)
      .navigationBarTitleDisplayMode(.inline)
      .onChange(of: selectedVideo) { _, video in
        guard let video else { return }
        selectedVideo = nil
        // Videos open in the canonical PiP-aware player cover;
        // the navigation push slid a second player page in.
        dependencies.playbackCoordinator.open(video)
      }
      .navigationDestination(item: $selectedChannelURL) { channelURL in
        LiveChannelView(
          channelURL: channelURL,
          dependencies: dependencies
        )
      }
      .task { await viewModel.prepare() }
      .alert("Library", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .accessibilityIdentifier("live.library.collection")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .cards)
    case let .failed(message):
      ContentUnavailableView {
        Label("Library unavailable", systemImage: "wifi.exclamationmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      loadedContent
    }
  }

  @ViewBuilder
  private var loadedContent: some View {
    if viewModel.videos.isEmpty {
      ContentUnavailableView(
        "No \(viewModel.kind.title.lowercased())",
        systemImage: viewModel.kind.symbol,
        description: Text("Videos saved here will appear in this collection.")
      ).liveThemedEmptyState()
    } else {
      ScrollView {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
          ForEach(viewModel.displayedVideos) { item in
            LiveCollectionVideoCard(
              item: item,
              dependencies: dependencies,
              onChannel: {
                guard !item.video.uploaderURL.isEmpty else { return }
                selectedChannelURL = item.video.uploaderURL
              },
              onSelect: { selectedVideo = item.video },
              onRemove: { pendingRemoval = item }
            )
            .popover(
              isPresented: Binding(
                get: { pendingRemoval?.id == item.id },
                set: { if !$0 { pendingRemoval = nil } }
              ),
              attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
              arrowEdge: .top
            ) {
              LiveConfirmCard(
                title: "Remove from \(viewModel.kind.title)?",
                confirmTitle: "Remove"
              ) {
                Task { await viewModel.remove(item) }
                pendingRemoval = nil
              }
            }
          }
        }
        .padding(16)
      }
      .refreshable { await viewModel.reload() }
      .background(DemoThemeBackground().ignoresSafeArea())
      .liveThemeRepaint()
    }
  }

  private var columns: [GridItem] {
    [
      GridItem(
        .adaptive(minimum: 330, maximum: 520),
        spacing: 22,
        alignment: .top
      ),
    ]
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
