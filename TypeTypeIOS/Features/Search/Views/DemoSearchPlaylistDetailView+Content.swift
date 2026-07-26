import SwiftUI

extension DemoSearchPlaylistDetailView {
  var playlistList: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
          Text("\(videos.count) videos")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        actionBar
        playlistSortBar
        if sortedVideos.isEmpty {
          ContentUnavailableView(
            "No videos yet",
            systemImage: "rectangle.stack.badge.plus",
            description: Text("Save a video from its action menu to fill this playlist.")
          )
          .frame(maxWidth: .infinity)
          .padding(.top, 34)
        } else {
          playlistGrid
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 14)
      .padding(.bottom, 36)
    }
    .background(DemoTheme.background)
  }

  private var playlistSortBar: some View {
    HStack {
      Text("\(videos.count) videos")
        .font(.headline)
      Spacer()
      Menu {
        ForEach(["Manual", "Newest", "Oldest", "Title"], id: \.self) { order in
          Button(order) {
            sortOrder = order
          }
        }
      } label: {
        Label(sortOrder, systemImage: "arrow.up.arrow.down")
          .font(.subheadline)
      }
    }
    .foregroundStyle(.primary)
  }

  private var playlistGrid: some View {
    LazyVStack(alignment: .leading, spacing: 12) {
      ForEach(Array(sortedVideos.prefix(visibleVideoCount))) { video in
        DemoPlaylistVideoCard(
          video: video,
          onSelect: { selectedVideo = video },
          onRemove: { pendingVideoRemoval = video },
          onMoveEarlier: {
            move(video, offset: -1)
          },
          onMoveLater: {
            move(video, offset: 1)
          },
          showsReorderActions: sortOrder == "Manual"
        )
        .accessibilityIdentifier("demo.playlist.video.\(video.id)")
        .draggable(video.id)
        .dropDestination(for: String.self) { identifiers, _ in
          guard sortOrder == "Manual", let sourceID = identifiers.first else {
            return false
          }
          reorder(sourceID: sourceID, before: video.id)
          return true
        }
      }

      DemoIncrementalLoadingTrigger(
        canLoadMore: visibleVideoCount < sortedVideos.count,
        isLoading: isLoadingMore,
        label: "Loading more playlist videos",
        identifier: "demo.playlist.loading",
        action: loadMore
      )
    }
  }

  private func loadMore() {
    guard !isLoadingMore, visibleVideoCount < sortedVideos.count else { return }
    isLoadingMore = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(380))
      withAnimation(.smooth(duration: 0.25)) {
        visibleVideoCount = min(sortedVideos.count, visibleVideoCount + 4)
      }
      try? await Task.sleep(for: .milliseconds(140))
      isLoadingMore = false
    }
  }

  private var actionBar: some View {
    HStack(spacing: 10) {
      Button {
        selectedVideo = sortedVideos.first
      } label: {
        Label("Play all", systemImage: "play.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(videos.isEmpty)

      Button {
        selectedVideo = videos.randomElement()
      } label: {
        Image(systemName: "shuffle")
          .frame(width: 38, height: 38)
      }
      .buttonStyle(.bordered)
      .disabled(videos.isEmpty)

      Button {
        session.toggleSavedPlaylist(playlist.id)
      } label: {
        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
          .frame(width: 38, height: 38)
      }
      .buttonStyle(.bordered)
      .opacity(playlist.isPublicSaved ? 1 : 0)
      .disabled(!playlist.isPublicSaved)
      .accessibilityHidden(!playlist.isPublicSaved)
    }
  }
}
