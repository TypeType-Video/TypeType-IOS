import SwiftUI
import UniformTypeIdentifiers

struct LiveImportView: View {
  @StateObject var viewModel: LiveImportViewModel
  @State var importsPipePipe = false
  @State var importsYouTube = false
  @State var timeMode = "normalized"
  @State var showsTakeoutGuide = false

  init(service: LiveImportServiceProtocol) {
    _viewModel = StateObject(
      wrappedValue: LiveImportViewModel(service: service)
    )
  }

  var body: some View {
    List {
      pipePipeSection
      youTubeSection
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
      allowsMultipleSelection: true
    ) { result in
      guard case let .success(urls) = result else { return }
      viewModel.queueYouTube(urls: urls)
    }
    .alert("Import", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .accessibilityIdentifier("live.import.screen")
  }

  var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }

}
