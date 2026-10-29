import SwiftUI

struct DemoSearchPlaylistDetailView: View {
  @Environment(\.themePalette) var palette
  @EnvironmentObject var session: DemoSessionStore
  let playlist: DemoPlaylist
  @State var title: String
  @State var videos: [DemoVideo]
  @State var selectedVideo: DemoVideo?
  @State var sortOrder = "Manual"
  @State var renamesPlaylist = false
  @State var renameDraft: String
  @State var isDeleted = false
  @State var deletedVideoIDs: Set<String> = []
  @State var confirmsDeletion = false
  @State var visibleVideoCount = 4
  @State var isLoadingMore = false
  @State var pendingVideoRemoval: DemoVideo?

  init(playlist: DemoPlaylist) {
    self.playlist = playlist
    _title = State(initialValue: playlist.title)
    _renameDraft = State(initialValue: playlist.title)
    _videos = State(initialValue: Array(DemoSearchCatalog.videos.prefix(6)))
  }

  var body: some View {
    Group {
      if isDeleted {
        deletedState
      } else {
        playlistList
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if !isDeleted {
        ToolbarItem(placement: .topBarTrailing) {
          playlistMenu
        }
      }
    }
    .alert("Rename playlist", isPresented: $renamesPlaylist) {
      TextField("Playlist name", text: $renameDraft)
      Button("Save") {
        let value = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty {
          title = value
          session.renamePlaylist(playlist.id, to: value)
        }
      }
      Button("Cancel", role: .cancel) {
        renameDraft = title
      }
    }
    .confirmationDialog(
      "Delete \(title)?",
      isPresented: $confirmsDeletion,
      titleVisibility: .visible
    ) {
      Button("Delete playlist", role: .destructive, action: deletePlaylist)
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This removes the local mock playlist and its manual ordering.")
    }
    .confirmationDialog(
      "Remove video?",
      isPresented: Binding(
        get: { pendingVideoRemoval != nil },
        set: { if !$0 { pendingVideoRemoval = nil } }
      ),
      titleVisibility: .visible
    ) {
      Button("Remove", role: .destructive) {
        if let pendingVideoRemoval {
          remove(pendingVideoRemoval)
        }
        pendingVideoRemoval = nil
      }
      Button("Cancel", role: .cancel) {
        pendingVideoRemoval = nil
      }
    } message: {
      Text("Remove this video from \(title)?")
    }
    .navigationDestination(item: $selectedVideo) { video in
      DemoWatchView(video: video)
    }
    .onAppear(perform: synchronizeBuiltInCollection)
    .onChange(of: session.favoriteVideoIDs) {
      synchronizeBuiltInCollection()
    }
    .onChange(of: session.watchLaterVideoIDs) {
      synchronizeBuiltInCollection()
    }
    .accessibilityIdentifier("demo.playlist-detail.screen")
  }

}
