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
      List {
        header
          .listRowBackground(Color.clear)
          .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
        if showsOptions {
          options
        }
        status
      }
      .liveGroupedList()
      .contentMargins(.top, 0, for: .scrollContent)
      .safeAreaInset(edge: .bottom) {
        if showsOptions {
          startButton
        }
      }
      .navigationTitle("Download")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .interactiveDismissDisabled(viewModel.isWorking && !viewModel.isFinishing)
    .accessibilityIdentifier("live.download.sheet")
    .task { await deArrowStore.prepare(viewModel.video) }
  }

  private var showsOptions: Bool {
    !viewModel.isWorking && viewModel.state != .done
  }

  private var header: some View {
    HStack(spacing: 12) {
      LiveRemoteImage(url: branding.thumbnailURL)
        .frame(width: 96, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 3) {
        Text(branding.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
        Text(viewModel.video.uploaderName)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var startButton: some View {
    Button {
      Task { await viewModel.start() }
    } label: {
      Label(viewModel.state == .idle ? "Download" : "Download again", systemImage: "arrow.down")
        .font(.headline)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }
    .liveProminentButton()
    .buttonBorderShape(.roundedRectangle(radius: 14))
    .disabled(!viewModel.canStart)
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .background(LiveThemeBackground().ignoresSafeArea())
    .accessibilityIdentifier("live.download.start")
  }

  var branding: LiveVideoBranding {
    deArrowStore.branding(for: viewModel.video)
  }
}
