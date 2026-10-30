import SwiftUI

extension LivePortabilityView {
  @ViewBuilder
  var jobSection: some View {
    if let job = viewModel.job {
      LiveSection {
        LabeledContent("Status", value: stateTitle(job))
        if let progress = job.progress {
          ProgressView(
            value: Double(progress.processed),
            total: Double(progress.total ?? max(progress.processed, 1))
          )
          LabeledContent(
            "Processed",
            value: progress.total == nil
              ? "\(progress.processed)"
              : "\(progress.processed) / \(progress.total!)"
          )
        }
        if job.state == .failed {
          Text(job.errorMessage ?? "The operation failed.")
            .foregroundStyle(.red)
        }
      } header: { Text("Job").liveSectionHeader() }

      if let preview = job.preview {
        LiveSection {
          LabeledContent(
            "Detected format",
            value: portabilityFormatTitle(
              preview.detection?.format ?? formatID(for: job.id)
            )
          )
          LabeledContent(
            "Duplicates",
            value: String(preview.duplicates)
          )
          ForEach(preview.issues) { issue in
            VStack(alignment: .leading) {
              Text(issue.message)
              Text("\(issue.count) item(s) · \(issue.code)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        } header: { Text("Preview").liveSectionHeader() }

        LiveSection {
          ForEach(viewModel.previewCategories) { category in
            LabeledContent(
              category.title,
              value: String(preview.counts[category.rawValue] ?? 0)
            )
          }
          Toggle("Skip duplicates", isOn: policyBinding)
          Button("Import selected") {
            Task { await viewModel.apply() }
          }
          .disabled(viewModel.isApplying || viewModel.selectedCategories.isEmpty)
        } header: { Text("Categories").liveSectionHeader() }
      }

      if !job.result.isEmpty {
        LiveSection {
          ForEach(job.result.sorted(by: { $0.key < $1.key }), id: \.key) {
            item in
            LabeledContent(
              LiveTypeTypeBackupCategory(rawValue: item.key)?.title ?? item.key,
              value: String(item.value)
            )
          }
        } header: { Text("Result").liveSectionHeader() }
      }

      LiveSection {
        if !job.isTerminal {
          Button("Cancel job", role: .destructive) {
            Task { await viewModel.cancel() }
          }
          .disabled(viewModel.isCancelling)
        }
        if job.state == .completed, job.kind == .export {
          Button("Prepare export for sharing") {
            Task {
              await viewModel.prepareDownload(kind: .artifact)
              if let url = viewModel.shareURL {
                LiveSystemSharePresenter.present(url)
              }
            }
          }
        }
        Button("Download report") {
          Task {
            await viewModel.prepareDownload(kind: .report)
            if let url = viewModel.shareURL {
              LiveSystemSharePresenter.present(url)
            }
          }
        }
        Button("Start another", role: .destructive) {
          Task { await viewModel.reset() }
        }
      } header: { Text("Actions").liveSectionHeader() }

      LiveSection {
        LabeledContent("Job ID", value: job.id)
        if let requestID = job.requestId {
          LabeledContent("Request ID", value: requestID)
        }
        if let errorCode = job.errorCode {
          LabeledContent("Error code", value: errorCode)
        }
      } header: { Text("Diagnostics").liveSectionHeader() }
    }
  }

  func formatID(for jobID: String) -> String {
    "typetype"
  }

  func portabilityFormatTitle(_ format: String) -> String {
    switch format.lowercased() {
    case "typetype": return "TypeType"
    case "youtubetakeout", "youtube-takeout": return "YouTube Takeout"
    case "opml": return "OPML"
    default: return format
    }
  }

  func stateTitle(_ job: LivePortabilityJob) -> String {
    switch job.state {
    case .queued: return "Waiting"
    case .analyzing: return "Analyzing"
    case .ready: return "Ready"
    case .applying: return "Importing"
    case .encoding: return "Generating export"
    case .completed: return job.kind == .import ? "Import completed" : "Export ready"
    case .cancelled: return "Cancelled"
    case .failed: return "Failed"
    }
  }
}
