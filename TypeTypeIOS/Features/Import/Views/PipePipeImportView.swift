import SwiftUI

struct PipePipeImportView: View {
  @StateObject private var viewModel: PipePipeImportViewModel

  init(service: PipePipeImportServiceProtocol) {
    _viewModel = StateObject(wrappedValue: PipePipeImportViewModel(service: service))
  }

  var body: some View {
    Form {
      ImportAssetBanner(title: "PipePipe migration", imageName: "import-dudu-cooking.gif")

      Section("PipePipe backup zip") {
        ZipPickerButton(
          title: "Choose ZIP",
          disabled: viewModel.isImporting,
          allowsMultipleSelection: false
        ) { urls in
          guard let first = urls.first else { return }
          if let archive = try? ImportArchiveAccess.prepare(url: first) {
            viewModel.setArchive(archive)
          }
        }

        if let selectedArchiveName = viewModel.selectedArchiveName {
          Text("Selected: \(selectedArchiveName)")
            .font(.caption)
            .foregroundStyle(.secondary)
          Button("Remove file", role: .destructive) {
            viewModel.clearArchive()
          }
          .disabled(viewModel.isImporting)
        }

        Button(viewModel.isImporting ? "Importing..." : "Start import") {
          Task { await viewModel.importSelectedArchive() }
        }
        .disabled(viewModel.isImporting || viewModel.selectedArchiveName == nil)
      }

      if let summary = viewModel.summary {
        Section("Imported") {
          LabeledContent("History", value: "\(summary.history)")
          LabeledContent("Subscriptions", value: "\(summary.subscriptions)")
          LabeledContent("Playlists", value: "\(summary.playlists)")
          LabeledContent("Progress entries", value: "\(summary.progress)")
        }
      }

      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .font(.footnote)
          .foregroundStyle(.red)
      }
    }
    .navigationTitle("Import PipePipe")
  }
}
