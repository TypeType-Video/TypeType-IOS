import SwiftUI

struct LiveDownloadSheet: View {
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
        Section {
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
      .liveThemeRepaint()
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
    // Only a live, cancellable transfer traps the sheet: "Saving on this
    // device" (finishing) and later states must let the user swipe away.
    .interactiveDismissDisabled(viewModel.isWorking && !viewModel.isFinishing)
    .accessibilityIdentifier("live.download.sheet")
    .task { await deArrowStore.prepare(viewModel.video) }
  }

}
