import SwiftUI

struct LiveDownloadSheet: View {
  @Environment(\.themePalette) var palette
  let dependencies: AppDependencies
  @ObservedObject var deArrowStore: LiveDeArrowStore
  @Environment(\.dismiss) var dismiss
  @StateObject var viewModel: LiveDownloadViewModel
  @State var stream: LivePlaybackStream?

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
          .liveBareRow()
        if showsOptions {
          options
          startButton
            .liveBareRow()
        }
        status
      }
      .liveGroupedList()
      .listSectionSpacing(.compact)
      .contentMargins(.top, 8, for: .scrollContent)
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
    .accessibilityIdentifier("live.download.sheet")
    .task { await deArrowStore.prepare(viewModel.video) }
    .task { await loadStream() }
  }

  private func loadStream() async {
    let playback = dependencies.playbackCoordinator
    if playback.currentVideo?.url == viewModel.video.url, let current = playback.controller?.stream {
      stream = current
      return
    }
    guard let service = dependencies.playbackService else { return }
    do {
      stream = try await service.stream(for: viewModel.video.url)
    } catch {
      AppLogger.network.failure("Loading streams for the download size", error)
    }
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
      Label(viewModel.state == .idle ? "Start download" : "Download again", systemImage: "arrow.down")
        .font(.headline)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }
    .liveProminentButton()
    .buttonBorderShape(.roundedRectangle(radius: 14))
    .disabled(!viewModel.canStart)
    .padding(.top, 4)
    .accessibilityIdentifier("live.download.start")
  }

  var branding: LiveVideoBranding {
    deArrowStore.branding(for: viewModel.video)
  }
}
