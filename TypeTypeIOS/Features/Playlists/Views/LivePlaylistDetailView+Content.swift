import SwiftUI

extension LivePlaylistDetailView {
  @ViewBuilder
  var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .rows, count: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView {
        Label("Playlist unavailable", systemImage: "wifi.exclamationmark")
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
    if let playlist = viewModel.playlist {
      if playlist.videos.isEmpty {
        ContentUnavailableView(
          "No videos",
          systemImage: "rectangle.stack.badge.plus",
          description: Text(
            "Add videos from their details page using Save to playlist."
          )
        ).liveThemedEmptyState()
      } else {
        List {
          if !playlist.description.isEmpty {
            Section {
              Text(playlist.description)
                .foregroundStyle(.secondary)
            }
          }
          Section {
            HStack(spacing: 12) {
              Button {
                startPlayback(
                  title: playlist.name,
                  videos: viewModel.videos.map(\.video),
                  shuffle: false
                )
              } label: {
                Label("Play all", systemImage: "play.fill")
                  .frame(maxWidth: .infinity)
              }
              .buttonStyle(.borderedProminent)

              Button {
                startPlayback(
                  title: playlist.name,
                  videos: viewModel.videos.map(\.video),
                  shuffle: true
                )
              } label: {
                Label("Shuffle", systemImage: "shuffle")
                  .frame(maxWidth: .infinity)
              }
              .buttonStyle(.bordered)
            }
          }
          Section {
            ForEach(viewModel.videos) { video in
              LivePlaylistVideoRow(
                video: video,
                dependencies: dependencies,
                onOpen: { selectedVideo = video.video },
                onChannel: {
                  guard !video.channelURL.isEmpty else { return }
                  selectedChannelURL = video.channelURL
                },
                onRemove: { pendingRemoval = video }
              )
              .liveConfirmPopover(
                isPresented: Binding(
                  get: { pendingRemoval?.id == video.id },
                  set: { if !$0 { pendingRemoval = nil } }
                ),
                title: "Remove video?",
                confirmTitle: "Remove"
              ) {
                Task { await viewModel.remove(video) }
                pendingRemoval = nil
              }
            }
            .onMove { source, destination in
              Task {
                await viewModel.move(
                  from: source,
                  to: destination
                )
              }
            }
          } header: { Text("\(playlist.videoCount) videos").liveSectionHeader() }
        }
          .liveThemedList()
        .refreshable { await viewModel.reload() }
      }
    }
  }

  var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }

  private func startPlayback(
    title: String,
    videos: [LiveVideoItem],
    shuffle: Bool
  ) {
    selectedVideo = dependencies.playbackCoordinator.startQueue(
      title: title,
      videos: videos,
      shuffle: shuffle
    )
  }
}
