import SwiftUI

extension LiveDownloadSheet {
  var options: some View {
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
        if formats.count == 1, let format = formats.first {
          LabeledContent("Format", value: format.uppercased())
        } else {
          Picker("Format", selection: $viewModel.format) {
            ForEach(formats, id: \.self) { value in
              Text(value.uppercased()).tag(value)
            }
          }
        }
      }
      processingOptions
      Section {
        Button("Start download", systemImage: "arrow.down.circle") {
          Task { await viewModel.start() }
        }
        .disabled(!viewModel.canStart)
      }
    }
  }

  @ViewBuilder private var processingOptions: some View {
    if viewModel.mode != .thumbnail {
      Section("Processing") {
        Toggle("Apply SponsorBlock", isOn: $viewModel.sponsorBlock)
        Toggle("Include subtitles", isOn: $viewModel.includesSubtitles)
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
  }

  private var qualities: [String] {
    switch viewModel.mode {
    case .thumbnail, .audio:
      return ["best"]
    case .video:
      return ["2160p", "1440p", "1080p", "720p", "480p", "360p"]
    }
  }

  private var formats: [String] {
    switch viewModel.mode {
    case .video: return ["mp4"]
    case .audio: return ["m4a"]
    case .thumbnail: return ["jpg", "png", "webp"]
    }
  }

  var branding: LiveVideoBranding {
    deArrowStore.branding(for: viewModel.video)
  }
}
