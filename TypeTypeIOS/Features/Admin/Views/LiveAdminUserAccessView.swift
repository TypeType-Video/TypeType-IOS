import SwiftUI

struct LiveAdminUserAccessView: View {
  @StateObject private var viewModel: LiveAdminUserAccessViewModel
  @State private var editor: Editor?

  init(userID: String, service: LiveAdminAccessServiceProtocol) {
    _viewModel = StateObject(
      wrappedValue: LiveAdminUserAccessViewModel(
        userID: userID,
        service: service
      )
    )
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .idle, .loading:
        TypeTypeSkeletonList(layout: .settings, count: 6, scrolls: false)
      case let .failed(message):
        ContentUnavailableView {
          Label("Access unavailable", systemImage: "person.crop.circle.badge.exclamationmark")
        } description: {
          Text(message)
        } actions: {
          Button("Try again") { Task { await viewModel.reload() } }
        }
      case .loaded:
        list
      }
    }
    .navigationTitle("User allow list")
    .navigationBarTitleDisplayMode(.inline)
    .task { await viewModel.prepare() }
    .sheet(item: $editor) { item in
      LiveAdminAllowedItemEditor(
        title: item == .channel ? "Add channel" : "Add playlist",
        label: item == .channel ? "Channel" : "Playlist",
        onSave: item == .channel
          ? viewModel.addChannel
          : viewModel.addPlaylist
      )
    }
  }

  private var list: some View {
    List {
      Section {
        LabeledContent("Name", value: viewModel.list?.user.name ?? "")
        Toggle(
          "Use a personal allow list",
          isOn: Binding(
            get: { viewModel.list?.user.accessMode == "allow_list" },
            set: { value in
              Task { await viewModel.setRestricted(value) }
            }
          )
        ).liveRowFill()
        .disabled(viewModel.isBusy)
      } header: { Text("User").liveSectionHeader() }

      channels(
        "Inherited global channels",
        items: viewModel.list?.globalChannels ?? [],
        removable: false
      )
      playlists(
        "Inherited global playlists",
        items: viewModel.list?.globalPlaylists ?? [],
        removable: false
      )
      channels(
        "User channels",
        items: viewModel.list?.userChannels ?? [],
        removable: true
      )
      playlists(
        "User playlists",
        items: viewModel.list?.userPlaylists ?? [],
        removable: true
      )
    }
      .liveGroupedList()
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu("Add", systemImage: "plus") {
          Button("Channel") { editor = .channel }
          Button("Playlist") { editor = .playlist }
        }
      }
    }
    .refreshable { await viewModel.reload() }
  }

  private func channels(
    _ title: String,
    items: [LiveContentControlItem],
    removable: Bool
  ) -> some View {
    Section(title) {
      ForEach(items) { item in
        LiveAdminAllowedChannelRow(item: item)
          .swipeActions {
            if removable {
              Button("Remove", role: .destructive) {
                Task { await viewModel.removeChannel(item) }
              }
            }
          }
      }
    }
  }

  private func playlists(
    _ title: String,
    items: [LiveAllowedPlaylistItem],
    removable: Bool
  ) -> some View {
    Section(title) {
      ForEach(items) { item in
        LiveAdminAllowedPlaylistRow(item: item)
          .swipeActions {
            if removable {
              Button("Remove", role: .destructive) {
                Task { await viewModel.removePlaylist(item) }
              }
            }
          }
      }
    }
  }

  private enum Editor: String, Identifiable {
    case channel, playlist
    var id: String { rawValue }
  }
}
