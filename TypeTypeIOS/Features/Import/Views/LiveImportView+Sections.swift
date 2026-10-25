import SwiftUI

extension LiveImportView {
  var typeTypeBackupSection: some View {
    Section {
      ForEach(LiveTypeTypeBackupCategory.allCases) { category in
        Toggle(category.title, isOn: categoryBinding(category))
          .disabled(viewModel.isRunning)
      }
      if let exportedBackupURL = viewModel.exportedBackupURL {
        ShareLink(
          item: exportedBackupURL,
          preview: SharePreview("TypeType backup", image: "externaldrive")
        ) {
          Label("Share backup", systemImage: "square.and.arrow.up")
        }
      } else {
        Label("Share backup", systemImage: "square.and.arrow.up")
          .foregroundStyle(.secondary)
      }
      Button {
        Task { await viewModel.exportTypeTypeBackup() }
      } label: {
        if viewModel.isExportingBackup {
          HStack {
            Text("Export selected data")
            Spacer()
            ProgressView()
          }
        } else {
          Label("Export selected data", systemImage: "square.and.arrow.down")
        }
      }
      .disabled(!viewModel.canExportTypeTypeBackup)
      .accessibilityIdentifier("live.import.typetype.export")
      if viewModel.isRestoringBackup {
        VStack(alignment: .leading, spacing: 6) {
          ProgressView(value: viewModel.backupProgress)
          Text(Self.backupPhaseTitle(viewModel.backupPhase))
            .font(.caption)
            .foregroundStyle(.secondary)
          Button("Cancel restore", role: .destructive) {
            viewModel.cancelTypeTypeRestore()
          }
        }
      } else if viewModel.hasResumableRestore {
        VStack(alignment: .leading, spacing: 6) {
          Text("An interrupted restore can be resumed.")
            .font(.caption)
            .foregroundStyle(.secondary)
          Button("Resume restore") {
            viewModel.resumeTypeTypeRestore()
          }
        }
      } else {
        Button {
          importsTypeTypeBackup = true
        } label: {
          Label("Restore TypeType backup", systemImage: "clock.arrow.circlepath")
        }
        .disabled(viewModel.isRunning)
      }
      if let summary = viewModel.typeTypeRestoreSummary {
        LabeledContent("Items restored", value: String(summary.total))
        ForEach(summary.restored.sorted(by: { $0.key < $1.key }), id: \.key) { item in
          LabeledContent(item.key, value: String(item.value))
        }
      }
    } header: { Text("TypeType backup").liveSectionHeader() } footer: {
      Text("Restore replaces matching data in this TypeType account. Export and restore use the selected categories.").liveSectionSlotChrome()
    }
  }

  private func categoryBinding(
    _ category: LiveTypeTypeBackupCategory
  ) -> Binding<Bool> {
    Binding(
      get: { viewModel.selectedBackupCategories.contains(category) },
      set: { _ in viewModel.toggleBackupCategory(category) }
    )
  }

  static func backupPhaseTitle(_ phase: LiveTypeTypeBackupPhase) -> String {
    switch phase {
    case .preparing: return String(localized: "Preparing backup")
    case .filtering: return String(localized: "Selecting categories")
    case .uploading: return String(localized: "Uploading restore")
    case .finalizing: return String(localized: "Finalizing restore")
    case .completed: return String(localized: "Restore complete")
    }
  }

  var pipePipeSection: some View {
    Section {
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
    } header: { Text("PipePipe").liveSectionHeader() }
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
    } header: { Text("YouTube Takeout").liveSectionHeader() } footer: {
      Text(
        "Archives are uploaded one at a time. "
          + "Subscriptions, playlists, favorites, Watch later, "
          + "and history are synchronized with this TypeType account."
      )
        .liveSectionSlotChrome()
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
