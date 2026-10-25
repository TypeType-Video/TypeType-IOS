import SwiftUI

struct LiveDownloadSheet: View {
  let dependencies: AppDependencies
  @ObservedObject var deArrowStore: LiveDeArrowStore
  @Environment(\.dismiss) var dismiss
  @StateObject var viewModel: LiveDownloadViewModel

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.dependencies = dependencies
    deArrowStore = dependencies.deArrowStore
    _viewModel = StateObject(
      wrappedValue: LiveDownloadViewModel(
        video: video,
        center: dependencies.downloadCenter
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
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DemoTheme.background)
      .navigationTitle("Download")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .interactiveDismissDisabled(viewModel.isWorking)
    .accessibilityIdentifier("live.download.sheet")
    .task { await deArrowStore.prepare(viewModel.video) }
  }

}
