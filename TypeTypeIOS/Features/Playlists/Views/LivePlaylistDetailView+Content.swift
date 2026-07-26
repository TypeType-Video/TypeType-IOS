import SwiftUI

extension LivePlaylistDetailView {
  @ViewBuilder
  var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView("Loading playlist")
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
        )
      } else {
        List {
          if !playlist.description.isEmpty {
            Section {
              Text(playlist.description)
                .foregroundStyle(.secondary)
            }
          }
          Section("\(playlist.videoCount) videos") {
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
            }
            .onMove { source, destination in
              Task {
                await viewModel.move(
                  from: source,
                  to: destination
                )
              }
            }
          }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.reload() }
      }
    }
  }

  @ToolbarContentBuilder
  var toolbarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarTrailing) {
      Menu {
        Picker("Sort", selection: $viewModel.sort) {
          ForEach(LivePlaylistDetailViewModel.Sort.allCases) {
            Text($0.title).tag($0)
          }
        }
        Divider()
        Button("Rename", systemImage: "pencil") {
          renamesPlaylist = true
        }
        Button(
          "Delete playlist",
          systemImage: "trash",
          role: .destructive
        ) {
          confirmsDeletion = true
        }
      } label: {
        Label("Playlist options", systemImage: "ellipsis.circle")
      }
      if viewModel.sort == .manual,
        viewModel.playlist?.videos.isEmpty == false {
        EditButton()
      }
    }
  }

  var removalBinding: Binding<Bool> {
    Binding(
      get: { pendingRemoval != nil },
      set: { if !$0 { pendingRemoval = nil } }
    )
  }

  var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
