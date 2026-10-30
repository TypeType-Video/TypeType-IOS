import SwiftUI

extension LiveDownloadSheet {
  var options: some View {
    Group {
      typePicker
        .liveBareRow()
      LiveSection {
        switch viewModel.mode {
        case .video:
          menuRow("Quality", icon: "sparkles.tv", selection: $viewModel.quality,
                  values: ["2160p", "1440p", "1080p", "720p", "480p", "360p"].map { ($0, $0) })
            .accessibilityIdentifier("live.download.quality")
        case .thumbnail:
          menuRow("Format", icon: "photo", selection: $viewModel.format,
                  values: [("jpg", "JPEG"), ("png", "PNG"), ("webp", "WebP")])
        case .audio:
          LivePlayerOptionLabel("Best audio quality", icon: "waveform")
        }
        if viewModel.mode != .thumbnail {
          LabeledContent {
            if let bytes = estimatedBytes {
              Text("About \(LiveDownloadTexts.size(bytes))")
            } else if stream == nil {
              ProgressView().controlSize(.small)
            } else {
              Text("Unknown")
            }
          } label: {
            LivePlayerOptionLabel("Size", icon: "internaldrive")
          }
          .accessibilityElement(children: .combine)
        }
        if viewModel.mode != .thumbnail {
          Toggle(isOn: $viewModel.sponsorBlock) {
            LivePlayerOptionLabel("Skip sponsors", icon: "forward.end", detail: "Cuts SponsorBlock segments out of the file.")
          }
          Toggle(isOn: $viewModel.includesSubtitles) {
            LivePlayerOptionLabel("Subtitles", icon: "captions.bubble")
          }
          if viewModel.includesSubtitles {
            menuRow("Subtitle language", icon: "globe", selection: $viewModel.subtitleLanguage,
                    values: LiveLanguageOptions.codes.map { ($0, LiveLanguageOptions.nativeName(of: $0)) })
          }
        }
      }
    }
  }

  private var estimatedBytes: Int64? {
    stream.flatMap { LiveDownloadSizeEstimate.bytes(for: $0, mode: viewModel.mode, quality: viewModel.quality) }
  }

  private var typePicker: some View {
    HStack(spacing: 10) {
      typeTile(.video, title: "Video", icon: "film")
      typeTile(.audio, title: "Audio", icon: "music.note")
      typeTile(.thumbnail, title: "Image", icon: "photo")
    }
    .accessibilityIdentifier("live.download.type")
  }

  private func typeTile(_ mode: LiveDownloadMode, title: LocalizedStringKey, icon: String) -> some View {
    let selected = viewModel.mode == mode
    return Button {
      viewModel.mode = mode
    } label: {
      VStack(spacing: 6) {
        Image(systemName: icon)
          .font(.title3)
        Text(title)
          .font(.subheadline.weight(.semibold))
      }
      .foregroundStyle(selected ? palette.accent : .primary)
      .frame(maxWidth: .infinity)
      .frame(height: 72)
      .background(
        selected ? palette.accent.opacity(0.14) : palette.rowBackground,
        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(selected ? palette.accent : .clear, lineWidth: 1.5)
      }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func menuRow(
    _ title: LocalizedStringKey,
    icon: String,
    selection: Binding<String>,
    values: [(String, String)]
  ) -> some View {
    HStack {
      LivePlayerOptionLabel(title, icon: icon)
      Spacer(minLength: 8)
      Menu {
        Picker(selection: selection) {
          ForEach(values, id: \.0) { value in
            Text(verbatim: value.1).tag(value.0)
          }
        } label: {
          EmptyView()
        }
        .pickerStyle(.inline)
      } label: {
        HStack(spacing: 4) {
          Text(verbatim: values.first { $0.0 == selection.wrappedValue }?.1 ?? selection.wrappedValue)
          Image(systemName: "chevron.up.chevron.down")
            .font(.footnote.weight(.semibold))
        }
        .fixedSize()
      }
      .accessibilityLabel(Text(title))
    }
  }
}
