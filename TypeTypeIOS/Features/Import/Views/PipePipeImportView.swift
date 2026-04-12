import SwiftUI

struct PipePipeImportView: View {
  @StateObject private var viewModel: PipePipeImportViewModel
  @State private var archivePath: String = ""

  init(service: PipePipeImportServiceProtocol) {
    _viewModel = StateObject(wrappedValue: PipePipeImportViewModel(service: service))
  }

  var body: some View {
    Form {
      ImportAssetBanner(title: "PipePipe migration", imageName: "import-dudu-cooking.gif")

      Section("PipePipe backup zip") {
        TextField("Absolute file path", text: $archivePath)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
        Button(viewModel.isImporting ? "Importing..." : "Start import") {
          let url = URL(fileURLWithPath: archivePath)
          Task { await viewModel.importArchive(fileURL: url) }
        }
        .disabled(viewModel.isImporting || archivePath.isEmpty)
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
