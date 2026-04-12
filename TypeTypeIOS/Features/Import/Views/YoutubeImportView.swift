import SwiftUI

struct YoutubeImportView: View {
  @StateObject private var viewModel: YoutubeImportViewModel

  init(service: YoutubeImportServiceProtocol) {
    _viewModel = StateObject(wrappedValue: YoutubeImportViewModel(service: service))
  }

  var body: some View {
    Form {
      ImportAssetBanner(title: "YouTube Takeout import", imageName: "import-cooking-chef.gif")

      Section("YouTube Takeout zip") {
        ZipPickerButton(
          title: "Add ZIP file(s)",
          disabled: viewModel.isBusy,
          allowsMultipleSelection: true
        ) { urls in
          let archives = urls.compactMap { try? ImportArchiveAccess.prepare(url: $0) }
          viewModel.enqueue(archives)
        }

        if viewModel.hasQueue {
          Text("Queue: \(viewModel.queueCount) file(s)")
            .font(.caption)
            .foregroundStyle(.secondary)
          ForEach(viewModel.queue) { archive in
            HStack {
              Text(archive.name)
                .font(.caption)
                .lineLimit(1)
              Spacer()
              Button(role: .destructive) {
                viewModel.removeFromQueue(archive.id)
              } label: {
                Image(systemName: "trash")
              }
              .disabled(viewModel.isBusy)
            }
          }
          Button("Clear queue", role: .destructive) {
            viewModel.clearQueue()
          }
          .disabled(viewModel.isBusy)
        }

        if let activeFileName = viewModel.activeFileName, viewModel.isBusy {
          Text("Processing: \(activeFileName)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Button(viewModel.isBusy ? "Processing..." : "Start import") {
          Task { await viewModel.startQueuedImport() }
        }
        .disabled(viewModel.isBusy || !viewModel.hasQueue)
      }

      if let job = viewModel.job {
        Section("Job") {
          LabeledContent("Status", value: job.status)
          LabeledContent("Phase", value: job.phase)
          LabeledContent("Progress", value: "\(job.progress)%")
        }
      }

      if let preview = viewModel.preview {
        Section("Preview counts") {
          LabeledContent("Subscriptions", value: "\(preview.counts.subscriptions)")
          LabeledContent("Playlists", value: "\(preview.counts.playlists)")
          LabeledContent("History", value: "\(preview.counts.history)")
        }
      }

      if let report = viewModel.report {
        Section("Import report") {
          LabeledContent("Subscriptions imported", value: "\(report.subscriptions.imported)")
          LabeledContent("Playlists imported", value: "\(report.playlists.imported)")
          LabeledContent("History imported", value: "\(report.history.imported)")
        }
      }

      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .font(.footnote)
          .foregroundStyle(.red)
      }
    }
    .navigationTitle("Import YouTube")
  }
}
