import SwiftUI

struct WatchActionsBar: View {
  @ObservedObject var actionsViewModel: WatchActionsViewModel
  let onNotInterested: () -> Void

  init(actionsViewModel: WatchActionsViewModel, onNotInterested: @escaping () -> Void = {}) {
    self.actionsViewModel = actionsViewModel
    self.onNotInterested = onNotInterested
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        Button {
          Task { await actionsViewModel.toggleFavorite() }
        } label: {
          Label(
            actionsViewModel.isFavorite ? "Favorited" : "Favorite",
            systemImage: actionsViewModel.isFavorite ? "heart.fill" : "heart"
          )
        }
        .buttonStyle(.bordered)

        Button {
          Task { await actionsViewModel.toggleWatchLater() }
        } label: {
          Label(
            actionsViewModel.isWatchLater ? "Saved" : "Watch Later",
            systemImage: actionsViewModel.isWatchLater ? "clock.fill" : "clock"
          )
        }
        .buttonStyle(.bordered)

        Button {
          Task { await actionsViewModel.toggleSubscription() }
        } label: {
          Label(
            actionsViewModel.isSubscribed ? "Subscribed" : "Subscribe",
            systemImage: actionsViewModel.isSubscribed ? "bell.fill" : "bell"
          )
        }
        .buttonStyle(.borderedProminent)

        Button {
          onNotInterested()
        } label: {
          Label("Less like this", systemImage: "hand.thumbsdown")
        }
        .buttonStyle(.bordered)

        Menu {
          ForEach(actionsViewModel.playlists) { playlist in
            Button {
              Task { await actionsViewModel.togglePlaylist(playlistID: playlist.id) }
            } label: {
              if actionsViewModel.playlistIDsContainingVideo.contains(playlist.id) {
                Label(playlist.name, systemImage: "checkmark")
              } else {
                Text(playlist.name)
              }
            }
          }
          Button("Create + Save") {
            Task { await actionsViewModel.createPlaylistAndAdd() }
          }
        } label: {
          Label("Save", systemImage: "text.badge.plus")
        }
        .buttonStyle(.bordered)
      }
    }
    .disabled(actionsViewModel.isMutating || actionsViewModel.isLoading)
  }
}
