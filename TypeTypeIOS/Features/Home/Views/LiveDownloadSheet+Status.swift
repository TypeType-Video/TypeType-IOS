import SwiftUI

extension LiveDownloadSheet {
  @ViewBuilder
  var status: some View {
    switch viewModel.state {
    case .idle:
      EmptyView()
    case .creating:
      LiveSection {
        HStack(spacing: 12) {
          ProgressView()
          Text("Starting the download")
        }
      }
    case .tracking:
      LiveSection {
        progressBlock
        Button("Cancel download", systemImage: "xmark", role: .destructive) {
          Task { await viewModel.cancel() }
        }
        .disabled(viewModel.isCancelling)
      }
    case .done:
      LiveSection {
        Label("Available offline", systemImage: "checkmark.circle.fill")
          .foregroundStyle(.green)
          .font(.headline)
        if let artifactURL = viewModel.artifactURL {
          ShareLink(item: artifactURL) {
            Label("Share the file", systemImage: "square.and.arrow.up")
          }
        }
        Button("Delete download", systemImage: "trash", role: .destructive) {
          Task { await viewModel.clear() }
        }
        .disabled(viewModel.isClearing)
      } footer: {
        Text("Find it any time in Library, Downloads.").liveSettingsFooter()
      }
    case let .failed(message):
      LiveSection {
        Label(message, systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
        if viewModel.job != nil {
          Button("Delete download", systemImage: "trash", role: .destructive) {
            Task { await viewModel.clear() }
          }
          .disabled(viewModel.isClearing)
        }
      }
    }
  }

  private var progressBlock: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(stageTitle)
        .font(.headline)
      if let progress = shownProgress {
        ProgressView(value: progress).tint(palette.accent)
      } else {
        ProgressView().frame(maxWidth: .infinity, alignment: .leading)
      }
      if let detail = progressDetail {
        Text(detail)
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      }
      if let waiting = viewModel.waitingMessage, !waiting.isEmpty {
        Label(waiting, systemImage: "wifi.exclamationmark")
          .font(.caption)
          .foregroundStyle(.orange)
      }
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }

  private var shownProgress: Double? {
    viewModel.isFinishing ? viewModel.savingProgress : viewModel.progress
  }

  // While saving, the job's own numbers are stale: they describe the finished server download.
  private var progressDetail: String? {
    guard viewModel.isFinishing else { return viewModel.job.flatMap(LiveDownloadTexts.transfer) }
    return viewModel.savingProgress.map(LiveDownloadTexts.percent)
  }

  private var stageTitle: String {
    if viewModel.isFinishing { return LiveManagedDownloadState.saving.title }
    switch viewModel.job?.stage {
    case "extract": return LiveManagedDownloadState.preparing.title
    case "mux": return LiveManagedDownloadState.finalizing.title
    case "queued": return LiveManagedDownloadState.queued.title
    default: return LiveManagedDownloadState.downloading.title
    }
  }
}
