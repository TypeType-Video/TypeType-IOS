import SwiftUI
import UniformTypeIdentifiers

struct LivePortabilityView: View {
  let importService: LiveImportServiceProtocol
  @StateObject private var viewModel: LivePortabilityViewModel
  @State private var showsFilePicker = false
  @State private var autoSharedJobID: String?

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

  private var jobActive: Bool {
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

  @ViewBuilder
  private var jobSection: some View {
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

  private var policyBinding: Binding<Bool> {
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

  private func formatID(for jobID: String) -> String {
    "typetype"
  }

  private func portabilityFormatTitle(_ format: String) -> String {
    switch format.lowercased() {
    case "typetype": return "TypeType"
    case "youtubetakeout", "youtube-takeout": return "YouTube Takeout"
    case "opml": return "OPML"
    default: return format
    }
  }

  private func stateTitle(_ job: LivePortabilityJob) -> String {
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

/// Presents the system share sheet from UIKit: the Liquid Glass sheet iOS
/// 26 shows for ShareLink. Wrapping UIActivityViewController in a SwiftUI
/// .sheet renders a plain page instead.
enum LiveSystemSharePresenter {
  @MainActor
  static func present(_ url: URL) {
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
      var top = scene.keyWindow?.rootViewController
    else { return }
    while let presented = top.presentedViewController {
      top = presented
    }
    let activity = UIActivityViewController(
      activityItems: [url],
      applicationActivities: nil
    )
    top.present(activity, animated: true)
  }
}
