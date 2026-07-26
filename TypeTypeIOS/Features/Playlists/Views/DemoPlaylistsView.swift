import SwiftUI

struct DemoPlaylistsView: View {
  @EnvironmentObject var session: DemoSessionStore
  let initialPlaylistID: String?
  @State var createsPlaylist = false
  @State var selectedPlaylist: DemoPlaylist?
  @State var isSelecting = false
  @State var selectedPlaylistIDs: Set<String> = []
  @State var pendingDeletionIDs: Set<String> = []

  private let columns = [
    GridItem(.adaptive(minimum: 150, maximum: 230), spacing: 16),
  ]

  init(initialPlaylistID: String? = nil) {
    self.initialPlaylistID = initialPlaylistID
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 30) {
          savedSection
          librarySection
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 32)
      }
      .background(DemoTheme.background)
      .navigationTitle("Playlists")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(isSelecting ? "Done" : "Select") {
            withAnimation {
              isSelecting.toggle()
              if !isSelecting {
                selectedPlaylistIDs.removeAll()
              }
            }
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          if isSelecting {
            Button("Delete", role: .destructive) {
              pendingDeletionIDs = selectedPlaylistIDs
            }
            .disabled(selectedPlaylistIDs.isEmpty)
          } else {
            Button {
              createsPlaylist = true
            } label: {
              Label("New playlist", systemImage: "plus")
            }
            .accessibilityIdentifier("demo.playlists.add")
          }
        }
      }
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(
        DemoTheme.background.opacity(0.96),
        for: .navigationBar
      )
      .sheet(isPresented: $createsPlaylist) {
        DemoPlaylistCreateSheet(onCreate: create)
      }
      .confirmationDialog(
        deletionTitle,
        isPresented: Binding(
          get: { !pendingDeletionIDs.isEmpty },
          set: { if !$0 { pendingDeletionIDs.removeAll() } }
        ),
        titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive, action: confirmDeletion)
        Button("Cancel", role: .cancel) {
          pendingDeletionIDs.removeAll()
        }
      } message: {
        Text("This removes the selected local mock playlists and their ordering.")
      }
      .navigationDestination(item: $selectedPlaylist) { playlist in
        DemoSearchPlaylistDetailView(playlist: playlist)
      }
      .onAppear(perform: openInitialPlaylist)
    }
    .accessibilityIdentifier("demo.playlists.screen")
  }

  private func openInitialPlaylist() {
    guard selectedPlaylist == nil, let initialPlaylistID else { return }
    guard let playlist = session.playlists.first(
      where: { $0.id == initialPlaylistID }
    ) else { return }
    selectedPlaylist = displayPlaylist(playlist)
  }

  private var savedSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text("Saved public playlists")
          .font(.headline)
          .foregroundStyle(.primary)
        Text("Live public collections saved to your library.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      ScrollView(.horizontal) {
        LazyHStack(alignment: .top, spacing: 14) {
          ForEach(savedPublicPlaylists) { playlist in
            let displayed = displayPlaylist(playlist)
            DemoPlaylistCard(playlist: displayed) {
              selectedPlaylist = displayed
            }
              .frame(width: 176)
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }

  private var librarySection: some View {
    VStack(alignment: .leading, spacing: 14) {
      DemoSectionLabel(title: "Your library")
      LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
        ForEach(session.playlists.filter { !$0.isPublicSaved }) { playlist in
          let displayed = displayPlaylist(playlist)
          DemoPlaylistCard(playlist: displayed) {
            select(displayed)
          }
          .overlay(alignment: .topTrailing) {
            selectionBadge(displayed.id)
          }
          .contextMenu {
            Button("Open", systemImage: "rectangle.stack") {
              selectedPlaylist = displayed
            }
            if !["favorites", "watch-later"].contains(displayed.id) {
              Button("Delete", systemImage: "trash", role: .destructive) {
                pendingDeletionIDs = [displayed.id]
              }
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private func selectionBadge(_ playlistID: String) -> some View {
    if isSelecting && !["favorites", "watch-later"].contains(playlistID) {
      Image(
        systemName: selectedPlaylistIDs.contains(playlistID)
          ? "checkmark.circle.fill"
          : "circle"
      )
      .font(.title2)
      .foregroundStyle(.white)
      .background(.black.opacity(0.55), in: Circle())
      .padding(8)
    }
  }

}
