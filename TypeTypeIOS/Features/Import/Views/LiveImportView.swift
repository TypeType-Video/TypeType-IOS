import SwiftUI
import UniformTypeIdentifiers

struct LiveImportView: View {
  @StateObject private var viewModel: LiveImportViewModel
  @State private var importsPipePipe = false
  @State private var importsYouTube = false
  @State private var timeMode = "normalized"

  init(service: LiveImportServiceProtocol) {
    _viewModel = StateObject(
      wrappedValue: LiveImportViewModel(service: service)
    )
  }

  var body: some View {
    List {
      Section("PipePipe") {
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
      }

      Section("YouTube Takeout") {
        Button("Choose YouTube Takeout ZIP") {
          importsYouTube = true
        }
        .disabled(viewModel.isRunning)
        if let job = viewModel.youTubeJob {
          ProgressView(
            value: Double(job.progress),
            total: 100
          ) {
            Text(job.phase.capitalized)
          } currentValueLabel: {
            Text("\(job.progress)%")
          }
        }
        if let preview = viewModel.youTubePreview {
          LiveYouTubeImportCountsView(
            title: "Detected",
            counts: preview.counts
          )
        }
        if let report = viewModel.youTubeReport {
          LiveYouTubeImportReportView(report: report)
        }
      }
    }
    .navigationTitle("Import")
    .navigationBarTitleDisplayMode(.inline)
    .fileImporter(
      isPresented: $importsPipePipe,
      allowedContentTypes: [.zip],
      allowsMultipleSelection: false
    ) { result in
      guard case let .success(urls) = result,
        let url = urls.first else { return }
      Task {
        await viewModel.restorePipePipe(url: url, timeMode: timeMode)
      }
    }
    .fileImporter(
      isPresented: $importsYouTube,
      allowedContentTypes: [.zip],
      allowsMultipleSelection: false
    ) { result in
      guard case let .success(urls) = result,
        let url = urls.first else { return }
      Task { await viewModel.importYouTube(url: url) }
    }
    .alert("Import", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .accessibilityIdentifier("live.import.screen")
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
