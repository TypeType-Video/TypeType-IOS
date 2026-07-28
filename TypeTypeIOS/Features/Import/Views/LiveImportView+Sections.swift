import SwiftUI

extension LiveImportView {
  var pipePipeSection: some View {
    Section("PipePipe") {
      Picker("Timestamp handling", selection: $timeMode) {
        Text("Normalized").tag("normalized")
        Text("Raw").tag("raw")
      }
      Button("Choose PipePipe backup ZIP") {
        importsPipePipe = true
      }
      .disabled(viewModel.isRunning)
      if let result = viewModel.pipePipeResult {
        LivePipePipeImportSummary(result: result)
      }
    }
  }

  var youTubeSection: some View {
    Section {
      Button {
        importsYouTube = true
      } label: {
        Label("Add Takeout archives", systemImage: "doc.badge.plus")
      }
      .disabled(viewModel.isRunning)
      takeoutGuide
      archiveQueue
    } header: {
      Text("YouTube Takeout")
    } footer: {
      Text(
        "Archives are uploaded one at a time. "
          + "Subscriptions, playlists, favorites, Watch later, "
          + "and history are synchronized with this TypeType account."
      )
    }
  }

  private var takeoutGuide: some View {
    DisclosureGroup(
      "How to export from YouTube",
      isExpanded: $showsTakeoutGuide
    ) {
      VStack(alignment: .leading, spacing: 8) {
        takeoutStep(1, "Open Google Takeout.")
        takeoutStep(
          2,
          "Deselect everything, then select YouTube and My Activity."
        )
        takeoutStep(3, "Choose ZIP format and create the export.")
        takeoutStep(
          4,
          "After the export is ready, add every downloaded ZIP here."
        )
        if let takeoutURL = URL(string: Self.takeoutURLString) {
          Link(destination: takeoutURL) {
            Label(
              "Open Google Takeout",
              systemImage: "arrow.up.right.square"
            )
          }
        }
      }
    }
  }

  @ViewBuilder private var archiveQueue: some View {
    if viewModel.youTubeArchives.isEmpty {
      emptyArchiveQueue
    } else {
      if viewModel.isRunning {
        VStack(alignment: .leading, spacing: 8) {
          ProgressView(value: viewModel.youTubeOverallProgress)
          Text(
            "\(viewModel.completedYouTubeArchiveCount) of "
              + "\(viewModel.youTubeArchives.count) archives completed"
          )
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }
      ForEach(viewModel.youTubeArchives) { archive in
        LiveYouTubeImportArchiveRow(
          archive: archive,
          isActive: archive.id == viewModel.activeYouTubeArchiveID
        )
        .swipeActions {
          if !viewModel.isRunning {
            Button("Remove", role: .destructive) {
              viewModel.removeYouTubeArchive(id: archive.id)
            }
          }
        }
      }
      Button {
        Task { await viewModel.startYouTubeQueue() }
      } label: {
        Label(
          viewModel.completedYouTubeArchiveCount == 0
            ? "Start import" : "Import remaining archives",
          systemImage: "arrow.down.doc.fill"
        )
      }
      .disabled(!viewModel.canStartYouTubeQueue)
      .accessibilityIdentifier("live.import.youtube.start")
      Button("Clear queue", role: .destructive) {
        viewModel.clearYouTubeQueue()
      }
      .disabled(viewModel.isRunning)
    }
  }

  private var emptyArchiveQueue: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: "tray")
        .font(.title2)
        .foregroundStyle(.secondary)
        .frame(width: 30)
      VStack(alignment: .leading, spacing: 3) {
        Text("No archives queued")
          .font(.subheadline.weight(.semibold))
        Text("Select one or more ZIP files to import them in order.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }

  private func takeoutStep(
    _ number: Int,
    _ text: String
  ) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text("\(number).")
        .font(.caption.monospacedDigit().weight(.semibold))
        .foregroundStyle(.secondary)
      Text(text).font(.callout)
    }
  }

  private static let takeoutURLString =
    "https://takeout.google.com/settings/takeout/"
    + "custom/youtube,my_activity?dest=mail&frequency=once"
}
