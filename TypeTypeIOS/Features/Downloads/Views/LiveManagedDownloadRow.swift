import SwiftUI

struct LiveManagedDownloadRow: View {
  let record: LiveManagedDownload
  let artifactURL: URL?
  let onCancel: () -> Void
  let onRetry: () -> Void
  let onRemove: () -> Void
  let onPlay: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      header
      progress
      failure
      actions
    }
    .padding(.vertical, 5)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("live.download.\(record.id)")
  }

  private var header: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: record.state.systemImage)
        .font(.title3)
        .foregroundStyle(statusColor)
        .frame(width: 28)
      VStack(alignment: .leading, spacing: 4) {
        Text(record.title)
          .font(.headline)
          .lineLimit(2)
        Text(record.state.title)
          .font(.subheadline)
          .foregroundStyle(statusColor)
        Text(selectionSummary)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
  }

  @ViewBuilder private var progress: some View {
    if record.state.isActive {
      if let value = record.progress {
        ProgressView(value: value).tint(DemoTheme.accent)
      } else {
        ProgressView()
      }
      if let transferDetail {
        Text(transferDetail)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  @ViewBuilder private var failure: some View {
    if let message = record.failureMessage {
      Text(message)
        .font(.caption)
        .foregroundStyle(
          record.state == .failed ? Color.red : Color.orange
        )
    }
  }

  private var actions: some View {
    HStack(spacing: 16) {
      playButton
      if let artifactURL {
        ShareLink(item: artifactURL) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      }
      stateAction
    }
    .font(.subheadline.weight(.medium))
    .buttonStyle(.borderless)
  }

  @ViewBuilder private var playButton: some View {
    if artifactURL != nil,
      record.options.mode != LiveDownloadMode.thumbnail.rawValue {
      Button(
        record.options.mode == LiveDownloadMode.audio.rawValue
          ? "Listen" : "Watch",
        systemImage: record.options.mode == LiveDownloadMode.audio.rawValue
          ? "headphones" : "play.circle.fill",
        action: onPlay
      )
      .accessibilityIdentifier("live.download.play.\(record.id)")
    }
  }

  @ViewBuilder private var stateAction: some View {
    if record.state.canCancel {
      Button(
        "Cancel",
        systemImage: "xmark.circle",
        role: .destructive,
        action: onCancel
      )
    } else if record.state.canRetry {
      Button(
        "Retry",
        systemImage: "arrow.clockwise",
        action: onRetry
      )
    }
    if !record.state.isActive {
      Button(
        "Remove",
        systemImage: "trash",
        role: .destructive,
        action: onRemove
      )
    }
  }

  private var statusColor: Color {
    switch record.state {
    case .ready: return .green
    case .failed: return .red
    case .cancelled: return .secondary
    default: return DemoTheme.accent
    }
  }

  private var selectionSummary: String {
    [
      record.options.mode.capitalized,
      record.options.quality.capitalized,
      record.options.format.uppercased(),
    ].joined(separator: " · ")
  }

  private var transferDetail: String? {
    var values: [String] = []
    if let downloaded = record.job.downloadedBytes {
      let downloadedText = ByteCountFormatter.string(
        fromByteCount: downloaded,
        countStyle: .file
      )
      if let total = record.job.totalBytes {
        values.append(
          "\(downloadedText) of \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))"
        )
      } else {
        values.append(downloadedText)
      }
    }
    if let speed = record.job.speedBytesPerSecond {
      values.append(
        "\(ByteCountFormatter.string(fromByteCount: speed, countStyle: .file))/s"
      )
    }
    if let eta = record.job.etaSeconds {
      values.append("\(eta)s remaining")
    }
    return values.isEmpty ? nil : values.joined(separator: " · ")
  }
}
