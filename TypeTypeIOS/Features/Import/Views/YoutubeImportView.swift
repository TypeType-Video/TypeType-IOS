import SwiftUI

struct YoutubeImportView: View {
  @StateObject private var viewModel: YoutubeImportViewModel
  @State private var archivePath: String = ""

  init(service: YoutubeImportServiceProtocol) {
    _viewModel = StateObject(wrappedValue: YoutubeImportViewModel(service: service))
  }

  var body: some View {
    Form {
      ImportAssetBanner(title: "YouTube Takeout import", imageName: "import-cooking-chef.gif")

      Section("YouTube Takeout zip") {
        TextField("Absolute file path", text: $archivePath)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
        Button(viewModel.isBusy ? "Processing..." : "Start import") {
          let url = URL(fileURLWithPath: archivePath)
          Task { await viewModel.startImport(archiveURL: url) }
        }
        .disabled(viewModel.isBusy || archivePath.isEmpty)
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
