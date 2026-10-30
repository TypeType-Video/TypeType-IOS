import SwiftUI
import UniformTypeIdentifiers

struct LivePortabilityView: View {
  let importService: LiveImportServiceProtocol
  @StateObject var viewModel: LivePortabilityViewModel
  @State var showsFilePicker = false
  @State var autoSharedJobID: String?

  init(
    service: LivePortabilityServiceProtocol,
    importService: LiveImportServiceProtocol
  ) {
    _viewModel = StateObject(
      wrappedValue: LivePortabilityViewModel(service: service)
    )
    self.importService = importService
  }

  var body: some View {
    Form {
      LiveSection {
        NavigationLink {
          LiveImportView(service: importService)
        } label: {
          VStack(alignment: .leading, spacing: 2) {
            Text("Import & restore")
            Text("PipePipe, YouTube Takeout, TypeType backups")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      } header: { Text("Tools").liveSectionHeader() }
      headerSection
      modeSection
      if jobActive {
        jobSection
      } else {
        setupSection
      }
    }
      .liveGroupedList()
    .navigationTitle("Data and backups")
    .navigationBarTitleDisplayMode(.inline)
    .task { await viewModel.prepare() }
    .fileImporter(
      isPresented: $showsFilePicker,
      allowedContentTypes: [.data],
      allowsMultipleSelection: false
    ) { result in
      if case let .success(urls) = result, let url = urls.first {
        viewModel.selectFile(url)
      }
    }
    .onChange(of: viewModel.job?.state) { _, state in
      guard state == .completed,
        let job = viewModel.job,
        job.kind == .export,
        autoSharedJobID != job.id
      else { return }
      autoSharedJobID = job.id
      Task {
        await viewModel.prepareDownload(kind: .artifact)
        if let url = viewModel.shareURL {
          LiveSystemSharePresenter.present(url)
        }
      }
    }
    .alert("Data and backups", isPresented: errorBinding) {
      Button("OK") { viewModel.errorMessage = nil }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
  }

  var jobActive: Bool {
    viewModel.job != nil
  }

  private var headerSection: some View {
    LiveSection {
      VStack(alignment: .leading, spacing: 6) {
        Text("Data portability")
          .font(.headline)
        Text(
          "Move account data into TypeType or create a backup for "
            + "another supported app."
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }
      .padding(.vertical, 2)
    }
  }

  private var modeSection: some View {
    LiveSection {
      Picker("Direction", selection: modeBinding) {
        ForEach(LivePortabilityViewModel.Mode.allCases) { mode in
          Text(mode.title).tag(mode)
        }
      }
      .pickerStyle(.segmented)
    } header: { Text("Direction").liveSectionHeader() }
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.errorMessage = nil } }
    )
  }

}
