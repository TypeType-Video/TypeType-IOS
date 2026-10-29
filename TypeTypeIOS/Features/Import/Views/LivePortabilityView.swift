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
      // The share sheet opens by itself the moment an export is ready.
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

  @ViewBuilder
  private var setupSection: some View {
    LiveSection {
      if viewModel.state == .loadingFormats {
        HStack {
          Text("Loading formats")
          Spacer()
          ProgressView()
        }
      } else if let format = viewModel.selectedFormat {
        Picker("Destination format", selection: formatBinding) {
          ForEach(viewModel.formats) { format in
            Text(portabilityFormatTitle(format.format)).tag(format)
          }
        }
        LabeledContent("Adapter", value: "v\(format.adapterVersion)")
      }
    } header: { Text("Format").liveSectionHeader() }

    if !viewModel.activeCategories.isEmpty {
      LiveSection {
        Button("Select all") {
          viewModel.selectedCategories = Set(
            viewModel.activeCategories.map(\.rawValue)
          )
        }
        ForEach(viewModel.activeCategories) { category in
          Toggle(category.title, isOn: categoryBinding(category))
        }
      } header: { Text("Categories").liveSectionHeader() }
    }

    actionSection
  }

  @ViewBuilder
  private var actionSection: some View {
    if viewModel.mode == .import {
      LiveSection {
        Button("Choose or drop a backup file") {
          showsFilePicker = true
        }
        if let name = viewModel.selectedFileName {
          LabeledContent("Selected", value: name)
        }
      } header: { Text("Backup file").liveSectionHeader() }
    }

    LiveSection {
      if viewModel.mode == .export {
        Button {
          Task { await viewModel.start() }
        } label: {
          if viewModel.isStartingJob {
            ProgressView()
          } else {
            Text("Generate export")
          }
        }
        .disabled(!viewModel.canStart)
      } else if let format = viewModel.selectedFormat {
        Button("Choose another backup") {
          showsFilePicker = true
        }
        Button {
          Task { await viewModel.start() }
        } label: {
          if viewModel.isStartingJob {
            ProgressView()
          } else {
            Text("Analyze \(portabilityFormatTitle(format.format))")
          }
        }
        .disabled(!viewModel.canStart)
      }
    } footer: {
      if viewModel.selectedCategories.isEmpty {
        Text("Select at least one category.")
      }
    }
  }

  private var modeBinding: Binding<LivePortabilityViewModel.Mode> {
    Binding(
      get: { viewModel.mode },
      set: { mode in Task { await viewModel.selectMode(mode) } }
    )
  }

  private var formatBinding: Binding<LivePortabilityFormat> {
    Binding(
      get: { viewModel.selectedFormat ?? viewModel.formats.first! },
      set: viewModel.selectFormat
    )
  }

  var policyBinding: Binding<Bool> {
    Binding(
      get: { viewModel.duplicatePolicy == .skip },
      set: {
        viewModel.duplicatePolicy = $0 ? .skip : .replace
      }
    )
  }

  private func categoryBinding(
    _ category: LiveTypeTypeBackupCategory
  ) -> Binding<Bool> {
    Binding(
      get: { viewModel.selectedCategories.contains(category.rawValue) },
      set: { _ in viewModel.toggle(category) }
    )
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.errorMessage = nil } }
    )
  }

}
