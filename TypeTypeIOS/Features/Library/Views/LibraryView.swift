import SwiftUI

struct LibraryView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: LibraryViewModel
  @State private var showCreatePlaylistSheet: Bool = false

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: LibraryViewModel(service: coordinator.dependencies.libraryService)
    )
  }

  @ViewBuilder
  private var content: some View {
    if let errorMessage = viewModel.errorMessage {
      Text(errorMessage)
        .font(.footnote)
        .foregroundStyle(.red)
        .padding(.horizontal)
    }

    Picker("Mode", selection: $viewModel.mode) {
      Text("History").tag(LibraryViewModel.Mode.history)
      Text("Playlists").tag(LibraryViewModel.Mode.playlists)
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)

    switch viewModel.mode {
    case .history:
      if viewModel.isLoadingHistory && viewModel.history.isEmpty {
        ProgressView("Loading history...")
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        List {
          Section("Filters") {
            TextField("Search history", text: $viewModel.historyQuery)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
            DatePicker("From", selection: $viewModel.historyFromDate, displayedComponents: [.date])
            DatePicker("To", selection: $viewModel.historyToDate, displayedComponents: [.date])
            Button("Apply filters") {
              Task { await viewModel.loadHistory() }
            }
          }

          Section {
            Button("Clear all history", role: .destructive) {
              Task { await viewModel.clearHistory() }
            }
            .disabled(viewModel.isMutatingHistory || viewModel.history.isEmpty)

            Button("Unsubscribe all channels", role: .destructive) {
              Task {
                await viewModel.unsubscribeAllChannels(using: coordinator.dependencies.subscriptionsService)
              }
            }
            .disabled(viewModel.isMutatingHistory)
          }

          ForEach(viewModel.history) { item in
            NavigationLink {
              WatchView(
                videoURL: item.url,
                coordinator: coordinator,
                watchService: coordinator.dependencies.watchService,
                watchProgressService: coordinator.dependencies.watchProgressService,
                watchActionsService: coordinator.dependencies.watchActionsService
              )
            } label: {
              LibraryHistoryRowView(item: item)
            }
            .swipeActions(edge: .trailing) {
              Button(role: .destructive) {
                Task { await viewModel.deleteHistoryEntry(item) }
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
        .listStyle(.plain)
      }
    case .playlists:
      if viewModel.isLoadingPlaylists && viewModel.playlists.isEmpty {
        ProgressView("Loading playlists...")
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        List {
          ForEach(viewModel.playlists) { playlist in
            NavigationLink {
              PlaylistDetailView(
                playlistID: playlist.id,
                coordinator: coordinator,
                libraryService: coordinator.dependencies.libraryService,
                watchService: coordinator.dependencies.watchService,
                watchProgressService: coordinator.dependencies.watchProgressService,
                watchActionsService: coordinator.dependencies.watchActionsService
              )
            } label: {
              LibraryPlaylistRowView(playlist: playlist)
            }
            .swipeActions(edge: .trailing) {
              Button(role: .destructive) {
                Task { await viewModel.deletePlaylist(playlist) }
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
        .listStyle(.plain)
      }
    }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 10) {
        content
      }
      .navigationTitle("Library")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          HStack(spacing: 12) {
            if viewModel.mode == .playlists {
              Button {
                showCreatePlaylistSheet = true
              } label: {
                Image(systemName: "plus")
              }
            }
            Button {
              Task { await viewModel.refreshCurrent() }
            } label: {
              Image(systemName: "arrow.clockwise")
            }
          }
        }
      }
      .sheet(isPresented: $showCreatePlaylistSheet) {
        CreatePlaylistSheet { name, description in
          Task { await viewModel.createPlaylist(name: name, description: description) }
        }
      }
    }
    .task {
      await viewModel.loadIfNeeded()
    }
  }
}
