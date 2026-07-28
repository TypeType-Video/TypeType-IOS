import SwiftUI

struct LiveYouTubeImportArchiveRow: View {
  let archive: LiveYouTubeImportArchive
  let isActive: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .foregroundStyle(iconColor)
          .frame(width: 24)
          .symbolEffect(.pulse, isActive: isActive)

        VStack(alignment: .leading, spacing: 2) {
          Text(archive.fileName)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
          Text(statusTitle)
            .font(.caption)
            .foregroundStyle(statusColor)
        }
        Spacer(minLength: 8)
        if isActive || isCompleted {
          Text("\(archive.progress)%")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
      }

      if isActive {
        ProgressView(
          value: Double(archive.progress),
          total: 100
        )
        .tint(DemoTheme.accent)
      }

      if let preview = archive.preview {
        DisclosureGroup("Detected data") {
          LiveYouTubeImportCountsView(
            title: "Ready to import",
            counts: preview.counts
          )
          messages(preview.warnings, icon: "exclamationmark.triangle")
          messages(
            preview.errors,
            icon: "xmark.octagon",
            color: .red
          )
        }
      }

      if let report = archive.report {
        DisclosureGroup("Import report") {
          LiveYouTubeImportReportView(report: report)
        }
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(
      "live.import.youtube.archive.\(archive.id.uuidString)"
    )
  }

  private var isCompleted: Bool {
    if case .completed = archive.state { return true }
    return false
  }

  private var statusTitle: String {
    switch archive.state {
    case .queued:
      return "Waiting"
    case .uploading:
      return "Uploading archive"
    case .previewing:
      return "Reading Takeout data"
    case .committing:
      return "Preparing synchronization"
    case .importing:
      return archive.job?.phase
        .replacingOccurrences(of: "_", with: " ")
        .capitalized ?? "Importing"
    case .completed:
      return "Completed"
    case let .failed(message):
      return message
    }
  }

  private var icon: String {
    switch archive.state {
    case .queued: return "tray"
    case .uploading: return "arrow.up.doc"
    case .previewing: return "doc.text.magnifyingglass"
    case .committing: return "checkmark.shield"
    case .importing: return "arrow.triangle.2.circlepath"
    case .completed: return "checkmark.circle.fill"
    case .failed: return "exclamationmark.triangle.fill"
    }
  }

  private var iconColor: Color {
    switch archive.state {
    case .completed: return .green
    case .failed: return .red
    default: return DemoTheme.accent
    }
  }

  private var statusColor: Color {
    if case .failed = archive.state { return .red }
    return .secondary
  }

  @ViewBuilder
  private func messages(
    _ values: [String],
    icon: String,
    color: Color = .secondary
  ) -> some View {
    ForEach(values, id: \.self) { value in
      Label(value, systemImage: icon)
        .font(.caption)
        .foregroundStyle(color)
    }
  }
}
