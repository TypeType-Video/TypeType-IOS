import SwiftUI

struct LiveDownloadSheet: View {
  @Environment(\.themePalette) var palette
  let dependencies: AppDependencies
  @ObservedObject var deArrowStore: LiveDeArrowStore
  @Environment(\.dismiss) var dismiss
  @StateObject var viewModel: LiveDownloadViewModel

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.dependencies = dependencies
    deArrowStore = dependencies.deArrowStore
    let stream = dependencies.playbackCoordinator.controller?.stream
    _viewModel = StateObject(
      wrappedValue: LiveDownloadViewModel(
        video: video,
        center: dependencies.downloadCenter,
        likeCount: stream?.likeCount ?? -1,
        dislikeCount: stream?.dislikeCount ?? -1
      )
    )
  }

  var body: some View {
    NavigationStack {
      Form {
        LiveSection {
          Text(branding.title)
            .font(.subheadline.weight(.semibold))
            .lineLimit(2)
        }

        if !viewModel.isWorking && viewModel.state != .done {
          options
        }

        status
      }
      .liveGroupedList()
      .navigationTitle("Download")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .interactiveDismissDisabled(viewModel.isWorking && !viewModel.isFinishing)
    .accessibilityIdentifier("live.download.sheet")
    .task { await deArrowStore.prepare(viewModel.video) }
  }

}
