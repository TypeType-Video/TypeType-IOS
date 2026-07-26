import SwiftUI

struct LiveDownloadSheet: View {
  let dependencies: AppDependencies
  @ObservedObject private var deArrowStore: LiveDeArrowStore
  @Environment(\.dismiss) private var dismiss
  @StateObject private var viewModel: LiveDownloadViewModel

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.dependencies = dependencies
    deArrowStore = dependencies.deArrowStore
    _viewModel = StateObject(
      wrappedValue: LiveDownloadViewModel(
        video: video,
        service: dependencies.downloaderService
      )
    )
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Text(branding.title)
            .font(.subheadline.weight(.semibold))
            .lineLimit(2)
        }

        if !viewModel.isWorking && viewModel.state != .done {
          options
        }

        status
      }
      .navigationTitle("Download")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .interactiveDismissDisabled(viewModel.isWorking)
    .accessibilityIdentifier("live.download.sheet")
    .task { await deArrowStore.prepare(viewModel.video) }
  }

  private var options: some View {
    Group {
      Section("Media") {
        Picker("Type", selection: $viewModel.mode) {
          ForEach(LiveDownloadMode.allCases) { mode in
            Text(mode.title).tag(mode)
          }
        }
        Picker("Quality", selection: $viewModel.quality) {
          ForEach(qualities, id: \.self) { value in
            Text(value.capitalized).tag(value)
          }
        }
        Picker("Format", selection: $viewModel.format) {
          ForEach(formats, id: \.self) { value in
            Text(value.uppercased()).tag(value)
          }
        }
      }

      if viewModel.mode != .thumbnail {
        Section("Processing") {
          Toggle("Apply SponsorBlock", isOn: $viewModel.sponsorBlock)
          Toggle(
            "Include subtitles",
            isOn: $viewModel.includesSubtitles
          )
          if viewModel.includesSubtitles {
            TextField(
              "Subtitle language",
              text: $viewModel.subtitleLanguage
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
          }
        }
      }

      Section {
        Button("Start download", systemImage: "arrow.down.circle") {
          Task { await viewModel.start() }
        }
        .disabled(!viewModel.canStart)
      }
    }
  }

  @ViewBuilder
  private var status: some View {
    switch viewModel.state {
    case .idle:
      EmptyView()
    case .creating:
      Section {
        HStack(spacing: 12) {
          ProgressView()
          Text("Creating download job")
        }
      }
    case .tracking:
      Section("Progress") {
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            Text(stageTitle)
            Spacer()
            if let percent = viewModel.job?.progressPercent {
              Text("\(percent)%")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
          }
          if let progress = viewModel.progress {
            ProgressView(value: progress)
              .tint(DemoTheme.accent)
          } else {
            ProgressView()
          }
          if let detail = transferDetail {
            Text(detail)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        Button("Cancel", role: .destructive) {
          Task { await viewModel.cancel() }
        }
        .disabled(viewModel.isCancelling)
      }
    case .done:
      Section("Ready") {
        Label(
          viewModel.job?.resolved?.fileName ?? "Download completed",
          systemImage: "checkmark.circle.fill"
        )
        .foregroundStyle(.green)
        if let artifactURL = viewModel.artifactURL(
          baseURL: dependencies.serverStore.selectedServer()?.baseURL
        ) {
          ShareLink(item: artifactURL) {
            Label("Open or save file", systemImage: "square.and.arrow.up")
          }
        }
        Button("Clear job", role: .destructive) {
          Task { await viewModel.clear() }
        }
        .disabled(viewModel.isClearing)
      }
    case let .failed(message):
      Section("Download failed") {
        Label(message, systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
        if viewModel.job != nil {
          Button("Clear job", role: .destructive) {
            Task { await viewModel.clear() }
          }
          .disabled(viewModel.isClearing)
        }
      }
    }
  }

  private var qualities: [String] {
    switch viewModel.mode {
    case .thumbnail:
      return ["best"]
    case .video, .audio:
      return ["best", "balanced", "small"]
    }
  }

  private var formats: [String] {
    switch viewModel.mode {
    case .video:
      return ["mp4", "mkv", "webm"]
    case .audio:
      return ["mp3", "m4a", "opus"]
    case .thumbnail:
      return ["jpg", "png", "webp"]
    }
  }

  private var stageTitle: String {
    switch viewModel.job?.stage {
    case "extract": return "Preparing media"
    case "download": return "Downloading"
    case "mux": return "Finalizing"
    case "queued": return "Waiting in queue"
    default:
      return viewModel.job?.status.capitalized ?? "Working"
    }
  }

  private var transferDetail: String? {
    guard let job = viewModel.job else { return nil }
    var values: [String] = []
    if let downloaded = job.downloadedBytes {
      let downloadedText = ByteCountFormatter.string(
        fromByteCount: downloaded,
        countStyle: .file
      )
      if let total = job.totalBytes {
        values.append(
          "\(downloadedText) of \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))"
        )
      } else {
        values.append(downloadedText)
      }
    }
    if let speed = job.speedBytesPerSecond {
      values.append(
        "\(ByteCountFormatter.string(fromByteCount: speed, countStyle: .file))/s"
      )
    }
    if let eta = job.etaSeconds {
      values.append("\(eta)s remaining")
    }
    return values.isEmpty ? nil : values.joined(separator: " · ")
  }

  private var branding: LiveVideoBranding {
    deArrowStore.branding(for: viewModel.video)
  }
}
