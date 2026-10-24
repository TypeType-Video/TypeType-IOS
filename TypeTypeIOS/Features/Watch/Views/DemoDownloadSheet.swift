import SwiftUI

struct DemoDownloadSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var session: DemoSessionStore
  let video: DemoVideo
  let onDone: (String) -> Void

  @State private var mode = "Video"
  @State private var quality = "Recommended (1080p)"
  @State private var includesSubtitles = true
  @State private var progress = 0.0
  @State private var isDownloading = false
  @State private var showsAllFormats = false
  @State private var errorMessage: String?
  @State private var downloadTask: Task<Void, Never>?

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker("Download mode", selection: $mode) {
            Text("Video").tag("Video")
            Text("Audio").tag("Audio")
          }
          .pickerStyle(.segmented)
        }

        Section(mode == "Video" ? "Video quality" : "Audio quality") {
          Picker("Preset", selection: $quality) {
            if mode == "Video" {
              Text("Best quality").tag("Best quality")
              Text("Recommended (1080p)").tag("Recommended (1080p)")
              Text("Balanced (720p)").tag("Balanced (720p)")
              Text("Small size (360p)").tag("Small size (360p)")
              if showsAllFormats {
                Text("Exact 1440p · WEBM").tag("Exact 1440p · WEBM")
                Text("Exact 480p · MP4").tag("Exact 480p · MP4")
                Text("Unavailable 4320p").tag("Unavailable 4320p")
              }
            } else {
              Text("Best sound").tag("Best sound")
              Text("Recommended").tag("Recommended")
              Text("Small size").tag("Small size")
            }
          }
          Toggle("Include subtitles", isOn: $includesSubtitles)
          Toggle("Show all formats", isOn: $showsAllFormats)
        }

        Section {
          LabeledContent("Container", value: mode == "Video" ? "MP4" : "M4A")
          LabeledContent("Size", value: mode == "Video" ? "142 MB" : "14 MB")
          LabeledContent("Destination", value: "Files / TypeType")
        } header: { Text("Estimated file").liveSectionHeader() }

        if isDownloading {
          Section {
            ProgressView(value: progress)
            Text(progress < 1 ? "Downloading and packaging…" : "Ready to open in Files")
              .font(.caption)
              .foregroundStyle(.secondary)
            Button("Cancel download", role: .destructive) {
              cancelDownload()
            }
          } header: { Text("Preparing offline copy").liveSectionHeader() }
        }

        if let errorMessage {
          Section {
            Label(errorMessage, systemImage: "externaldrive.badge.exclamationmark")
              .foregroundStyle(.red)
            Button("Clear error") {
              self.errorMessage = nil
              quality = "Recommended (1080p)"
            }
          } header: { Text("Download failed").liveSectionHeader() }
        }
      }
      .navigationTitle("Download")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(isDownloading ? "Working…" : "Start") {
            startDownload()
          }
          .disabled(isDownloading)
        }
      }
    }
    .presentationDetents([.medium, .large])
    .preferredColorScheme(session.preferences.colorScheme)
    .onChange(of: mode) {
      quality = mode == "Video" ? "Recommended (1080p)" : "Recommended"
      errorMessage = nil
    }
    .onDisappear {
      downloadTask?.cancel()
    }
    .accessibilityIdentifier("demo.watch.download")
  }

  private func startDownload() {
    if quality == "Unavailable 4320p" {
      errorMessage = "Requested 4320p is unavailable. Pick another format."
      return
    }
    errorMessage = nil
    isDownloading = true
    progress = 0.08
    downloadTask = Task { @MainActor in
      for value in [0.22, 0.46, 0.71, 0.9, 1.0] {
        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.16)) {
          progress = value
        }
      }
      try? await Task.sleep(for: .milliseconds(260))
      guard !Task.isCancelled else { return }
      session.completeDownload(for: video)
      onDone("\(video.title) is ready offline")
      dismiss()
    }
  }

  private func cancelDownload() {
    downloadTask?.cancel()
    downloadTask = nil
    isDownloading = false
    errorMessage = "Download cancelled. Clear the error to choose another format."
  }
}
