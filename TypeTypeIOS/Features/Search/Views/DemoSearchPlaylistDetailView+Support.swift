import SwiftUI

extension DemoSearchPlaylistDetailView {
  func videoRow(_ video: DemoVideo) -> some View {
    HStack(spacing: 12) {
      DemoArtworkView(video: video)
        .frame(width: 126, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 10))
      VStack(alignment: .leading, spacing: 4) {
        Text(video.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)
        Text(video.channel)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }

  var playlistMenu: some View {
    Menu {
      if isEditablePlaylist {
        Button("Rename", systemImage: "pencil") {
          renameDraft = title
          renamesPlaylist = true
        }
      }
      Menu("Sort", systemImage: "arrow.up.arrow.down") {
        ForEach(["Manual", "Newest", "Oldest", "Title"], id: \.self) { order in
          Button(order) {
            sortOrder = order
          }
        }
      }
      if playlist.isPublicSaved && isSaved {
        Button("Remove from library", systemImage: "bookmark.slash") {
          session.toggleSavedPlaylist(playlist.id)
        }
      } else if isEditablePlaylist {
        Button("Delete playlist", systemImage: "trash", role: .destructive) {
          confirmsDeletion = true
        }
      }
    } label: {
      Image(systemName: "ellipsis.circle")
    }
  }

  func deletePlaylist() {
    withAnimation {
      deletedVideoIDs = Set(videos.map(\.id))
      session.deletePlaylist(playlist.id)
      isDeleted = true
    }
  }

  var isEditablePlaylist: Bool {
    !["favorites", "watch-later"].contains(playlist.id)
      && !playlist.isPublicSaved
      && session.playlists.contains { $0.id == playlist.id }
  }

  var deletedState: some View {
    ContentUnavailableView {
      Label("Playlist deleted", systemImage: "trash")
    } description: {
      Text("The deletion only affects this local mock session.")
    } actions: {
      Button("Restore") {
        withAnimation {
          session.restorePlaylist(currentPlaylist)
          for videoID in deletedVideoIDs {
            session.setVideo(videoID, in: playlist.id, isIncluded: true)
          }
          isDeleted = false
        }
      }
      .buttonStyle(.borderedProminent)
    }
  }

  var sortedVideos: [DemoVideo] {
    switch sortOrder {
    case "Newest":
      return Array(videos.reversed())
    case "Oldest":
      return videos
    case "Title":
      return videos.sorted { $0.title < $1.title }
    default:
      return videos
    }
  }

  var isSaved: Bool {
    session.savedPublicPlaylistIDs.contains(playlist.id)
  }

  var currentPlaylist: DemoPlaylist {
    DemoPlaylist(
      id: playlist.id,
      title: title,
      detail: "\(videos.count) videos",
      artwork: playlist.artwork,
      isPublicSaved: playlist.isPublicSaved
    )
  }

  func move(from source: IndexSet, to destination: Int) {
    videos.move(fromOffsets: source, toOffset: destination)
  }

  func reorder(sourceID: String, before destinationID: String) {
    guard
      let source = videos.firstIndex(where: { $0.id == sourceID }),
      let destination = videos.firstIndex(where: { $0.id == destinationID }),
      source != destination
    else { return }
    let video = videos.remove(at: source)
    videos.insert(video, at: source < destination ? destination - 1 : destination)
  }

  func move(_ video: DemoVideo, offset: Int) {
    guard let source = videos.firstIndex(of: video) else { return }
    let destination = min(max(0, source + offset), videos.count - 1)
    guard source != destination else { return }
    withAnimation(.snappy) {
      videos.move(
        fromOffsets: IndexSet(integer: source),
        toOffset: destination > source ? destination + 1 : destination
      )
    }
  }

  func remove(_ video: DemoVideo) {
    withAnimation {
      switch playlist.id {
      case "favorites":
        session.favoriteVideoIDs.remove(video.id)
      case "watch-later":
        session.watchLaterVideoIDs.remove(video.id)
      default:
        session.setVideo(video.id, in: playlist.id, isIncluded: false)
        videos.removeAll { $0.id == video.id }
      }
    }
  }

  func synchronizeBuiltInCollection() {
    let ids: Set<String>?
    switch playlist.id {
    case "favorites":
      ids = session.favoriteVideoIDs
    case "watch-later":
      ids = session.watchLaterVideoIDs
    default:
      ids = session.playlistVideoIDs[playlist.id]
    }
    guard let ids else { return }
    videos = DemoSearchCatalog.videos.filter { ids.contains($0.id) }
    visibleVideoCount = min(max(4, visibleVideoCount), max(4, videos.count))
  }
}
