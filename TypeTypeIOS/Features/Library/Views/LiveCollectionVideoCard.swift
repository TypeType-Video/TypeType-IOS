import SwiftUI

struct LiveCollectionVideoCard: View {
  let item: LiveLibraryVideo
  let dependencies: AppDependencies
  let onChannel: () -> Void
  let onSelect: () -> Void
  let onRemove: () -> Void

  var body: some View {
    LiveVideoCard(
      video: item.video,
      deArrowStore: dependencies.deArrowStore,
      onChannel: onChannel,
      action: onSelect
    )
      .liveVideoQuickActions(
        video: item.video,
        dependencies: dependencies,
        onOpenChannel: onChannel,
        removeLabel: "Remove from collection",
        onRemove: onRemove
      )
      .accessibilityIdentifier("live.library.video")
  }
}
