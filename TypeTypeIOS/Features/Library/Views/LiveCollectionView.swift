import SwiftUI

struct LiveCollectionView: View {
  let dependencies: AppDependencies
  @StateObject private var viewModel: LiveCollectionViewModel
  @State private var selectedVideo: LiveVideoItem?
  @State private var selectedChannelURL: String?
  @State private var pendingRemoval: LiveLibraryVideo?

  init(
    kind: LiveLibraryCollectionKind,
    dependencies: AppDependencies
  ) {
    self.dependencies = dependencies
    _viewModel = StateObject(
      wrappedValue: LiveCollectionViewModel(
        kind: kind,
        service: dependencies.libraryService
      )
    )
  }

  var body: some View {
    content
      .navigationTitle(viewModel.kind.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Picker("Sort", selection: $viewModel.sort) {
              ForEach(LiveCollectionViewModel.Sort.allCases) {
                Text($0.title).tag($0)
              }
            }
          } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
          }
          .disabled(viewModel.videos.isEmpty)
        }
      }
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
      .confirmationDialog(
        "Remove from \(viewModel.kind.title)?",
        isPresented: removalBinding,
        titleVisibility: .visible
      ) {
        Button("Remove", role: .destructive) {
          guard let item = pendingRemoval else { return }
          Task { await viewModel.remove(item) }
          pendingRemoval = nil
        }
      }
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
      ProgressView("Loading \(viewModel.kind.title.lowercased())")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
      )
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
          }
        }
        .padding(16)
      }
      .refreshable { await viewModel.reload() }
      .background(DemoThemeBackground())
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

  private var removalBinding: Binding<Bool> {
    Binding(
      get: { pendingRemoval != nil },
      set: { if !$0 { pendingRemoval = nil } }
    )
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
