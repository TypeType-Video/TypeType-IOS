import SwiftUI

struct WatchActionsBar: View {
  @ObservedObject var actionsViewModel: WatchActionsViewModel

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
      }
    }
    .disabled(actionsViewModel.isMutating || actionsViewModel.isLoading)
  }
}
