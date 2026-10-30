import SwiftUI

extension LiveDownloadSheet {
  @ViewBuilder
  var status: some View {
    switch viewModel.state {
    case .idle:
      EmptyView()
    case .creating:
      Section {
        HStack(spacing: 12) {
          ProgressView()
          Text("Creating download job")
        }
      }
    case .tracking:
      trackingStatus
    case .done:
      readyStatus
    case let .failed(message):
      failedStatus(message)
    }
  }

  private var trackingStatus: some View {
    Section {
      VStack(alignment: .leading, spacing: 10) {
        if viewModel.isFinishing {
          HStack(spacing: 12) {
            ProgressView()
            Text("Saving on this device")
          }
          if let transferDetail {
            Text(transferDetail)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        } else {
          HStack {
            Text(stageTitle)
            Spacer()
            if let percent = viewModel.job?.progressPercent {
              Text("\(percent)%")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
          }
          if let progress = viewModel.progress {
            ProgressView(value: progress)
              .tint(palette.accent)
          } else {
            ProgressView()
          }
          if let transferDetail {
            Text(transferDetail)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Button("Cancel", role: .destructive) {
            Task { await viewModel.cancel() }
          }
          .disabled(viewModel.isCancelling)
        }
      }
    } header: { Text("Progress").liveSectionHeader() }
  }

  private var readyStatus: some View {
    Section {
      Label(
        viewModel.job?.resolved?.fileName ?? "Download completed",
        systemImage: "checkmark.circle.fill"
      )
      .foregroundStyle(.green)
      if let artifactURL = viewModel.artifactURL {
        ShareLink(item: artifactURL) {
          Label("Open or save file", systemImage: "square.and.arrow.up")
        }
      }
      Button("Clear job", role: .destructive) {
        Task { await viewModel.clear() }
      }
      .disabled(viewModel.isClearing)
    } header: { Text("Ready").liveSectionHeader() }
  }

  private func failedStatus(_ message: String) -> some View {
    Section {
      Label(message, systemImage: "exclamationmark.triangle.fill")
        .foregroundStyle(.red)
      if viewModel.job != nil {
        Button("Retry", systemImage: "arrow.clockwise") {
          Task { await viewModel.start() }
        }
        .disabled(!viewModel.canStart)
        Button("Clear job", role: .destructive) {
          Task { await viewModel.clear() }
        }
        .disabled(viewModel.isClearing)
      }
    } header: { Text("Download failed").liveSectionHeader() }
  }

  private var stageTitle: String {
    switch viewModel.job?.stage {
    case "extract": return "Preparing media"
    case "download": return "Downloading"
    case "mux": return "Finalizing"
    case "queued": return "Waiting in queue"
    default:
      return viewModel.job?.status.capitalized ?? "Working"
    }
  }

  private var transferDetail: String? {
    guard let job = viewModel.job else { return nil }
    var values: [String] = []
    if let downloaded = job.downloadedBytes {
      let downloadedText = ByteCountFormatter.string(
        fromByteCount: downloaded,
        countStyle: .file
      )
      if let total = job.totalBytes {
        values.append(
          "\(downloadedText) of \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))"
        )
      } else {
        values.append(downloadedText)
      }
    }
    if let speed = job.speedBytesPerSecond {
      values.append(
        "\(ByteCountFormatter.string(fromByteCount: speed, countStyle: .file))/s"
      )
    }
    if let eta = job.etaSeconds {
      values.append("\(eta)s remaining")
    }
    return values.isEmpty ? nil : values.joined(separator: " · ")
  }
}
