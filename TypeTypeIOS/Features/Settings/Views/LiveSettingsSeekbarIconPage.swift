import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct LiveSettingsSeekbarIconPage: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  @StateObject private var icons: LiveSeekbarIconViewModel
  let canUpload: Bool
  @State private var pickingPhoto = false
  @State private var pickingFile = false
  @State private var photo: PhotosPickerItem?

  init(viewModel: LiveSettingsViewModel, service: LiveProfileServiceProtocol, canUpload: Bool) {
    self.viewModel = viewModel
    self.canUpload = canUpload
    _icons = StateObject(wrappedValue: LiveSeekbarIconViewModel(service: service, settings: viewModel))
  }

  var body: some View {
    LiveSettingsEditingPage(viewModel: viewModel) {
      LiveSection {
        LiveSeekbarIconPreview(icon: LiveSeekbarIcon(settings: viewModel.draft))
      } footer: {
        Text(
          canUpload
            ? "It moves along the progress bar on every device you are signed in to."
            : "It moves along the progress bar on every device you are signed in to. Sign in to use your own image."
        )
        .liveSettingsFooter()
      }
      LiveSection {
        ForEach(LiveSeekbarIconChoice.allCases) { choice in
          choiceRow(choice)
        }
      } header: {
        Text("Icon").liveSectionHeader()
      }
      if canUpload {
        imageSection
      }
    }
    .photosPicker(isPresented: $pickingPhoto, selection: $photo, matching: .images)
    .fileImporter(isPresented: $pickingFile, allowedContentTypes: [.png, .jpeg, .gif, .webP]) { result in
      guard case let .success(url) = result else { return }
      Task {
        let data = await Task.detached(priority: .userInitiated) { Self.read(url) }.value
        await icons.upload(data)
      }
    }
    .onChange(of: photo) {
      guard let item = photo else { return }
      photo = nil
      Task { await icons.upload(try? await item.loadTransferable(type: Data.self)) }
    }
    .navigationTitle("Seekbar icon")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var shown: LiveSeekbarIconChoice { LiveSeekbarIconChoice.shown(for: viewModel.draft) }

  private var hasCustom: Bool { !(viewModel.draft.seekbarIconUrl ?? "").isEmpty }

  private func choiceRow(_ choice: LiveSeekbarIconChoice) -> some View {
    Button {
      if choice == .custom, !hasCustom {
        pickingPhoto = true
      } else {
        viewModel.draft.seekbarIcon = choice.rawValue
      }
    } label: {
      HStack {
        Text(choice.title).foregroundStyle(.primary)
        Spacer()
        if shown == choice {
          Image(systemName: "checkmark")
            .foregroundStyle(.tint)
            .accessibilityHidden(true)
        }
      }
    }
    .disabled(icons.isBusy || (choice == .custom && !hasCustom && !canUpload))
    .accessibilityAddTraits(shown == choice ? .isSelected : [])
  }

  private var imageSection: some View {
    LiveSection {
      Button(hasCustom ? "Change image" : "Choose from Photos", systemImage: "photo") { pickingPhoto = true }
      Button("Choose a file", systemImage: "folder") { pickingFile = true }
      if hasCustom {
        Button("Remove my image", systemImage: "trash", role: .destructive) {
          Task { await icons.remove() }
        }
      }
    } header: {
      Text("My image").liveSectionHeader()
    } footer: {
      if icons.isBusy {
        ProgressView().frame(maxWidth: .infinity, alignment: .leading)
      } else if let failure = icons.failure {
        Text(Self.message(failure)).font(.footnote).foregroundStyle(.red)
      } else {
        Text("PNG, JPEG, GIF or WebP, 2 MB at most. GIFs stay animated.").liveSettingsFooter()
      }
    }
    .disabled(icons.isBusy)
  }

  private static func message(_ failure: LiveSeekbarIconViewModel.Failure) -> LocalizedStringKey {
    switch failure {
    case .unsupported: "Use a PNG, JPEG, GIF or WebP image."
    case .tooLarge: "This image is larger than 2 MB."
    case .failed: "The image could not be saved. Try again."
    }
  }

  private nonisolated static func read(_ url: URL) -> Data? {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    guard size <= 40 * 1_024 * 1_024 else { return nil }
    return try? Data(contentsOf: url)
  }
}

struct LiveSeekbarIconPreview: View {
  let icon: LiveSeekbarIcon

  var body: some View {
    GeometryReader { proxy in
      let thumb = LiveSeekbarThumb.size(for: icon, isScrubbing: false)
      ZStack(alignment: .leading) {
        Capsule().fill(.secondary.opacity(0.35)).frame(height: 4)
        Capsule().fill(.tint).frame(width: proxy.size.width * 0.4, height: 4)
        LiveSeekbarThumb(icon: icon, isScrubbing: false)
          .offset(x: proxy.size.width * 0.4 - thumb / 2)
      }
      .frame(maxHeight: .infinity)
    }
    .frame(height: 44)
    .accessibilityHidden(true)
  }
}
