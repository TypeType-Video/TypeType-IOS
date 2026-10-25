import SwiftUI

struct DemoDownloadsView: View {
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    List {
      Section {
        ForEach($session.downloads) { $download in
          row($download)
        }
      } header: { Text("\(readyCount) ready offline").liveSectionHeader() } footer: {
        Text("All files and progress on this screen are local mock data.").liveSectionSlotChrome()
      }
    }
      .listStyle(.insetGrouped)
    .navigationTitle("Downloads")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button("Resume all", systemImage: "play.fill") {
            for item in session.downloads where item.phase != "ready" {
              resume(id: item.id)
            }
          }
          Button("Clear completed", systemImage: "checkmark.circle") {
            withAnimation {
              session.downloads.removeAll { $0.phase == "ready" }
            }
          }
          Button("Clear failed", systemImage: "xmark.circle") {
            withAnimation {
              session.downloads.removeAll {
                ["failed", "cancelled"].contains($0.phase)
              }
            }
          }
        } label: {
          Label("Download actions", systemImage: "ellipsis.circle")
        }
      }
    }
    .accessibilityIdentifier("demo.downloads.screen")
  }

  private func row(_ download: Binding<DemoDownloadItem>) -> some View {
    HStack(spacing: 13) {
      DemoChannelAvatar(
        name: download.wrappedValue.title,
        artwork: download.wrappedValue.artwork,
        size: 48
      )
      VStack(alignment: .leading, spacing: 5) {
        Text(download.wrappedValue.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
        ProgressView(value: download.wrappedValue.progress)
          .tint(Color(red: 1, green: 0.3, blue: 0.34))
        Text(download.wrappedValue.status)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 4)
      Menu {
        switch download.wrappedValue.phase {
        case "running":
          Button("Pause", systemImage: "pause.fill") {
            update(id: download.wrappedValue.id, phase: "paused")
          }
          Button("Cancel", systemImage: "xmark", role: .destructive) {
            update(id: download.wrappedValue.id, phase: "cancelled")
          }
        case "ready":
          ShareLink(
            item: "Mock offline file for \(download.wrappedValue.title)"
          ) {
            Label("Share file", systemImage: "square.and.arrow.up")
          }
        default:
          Button("Resume", systemImage: "play.fill") {
            resume(id: download.wrappedValue.id)
          }
        }
        if download.wrappedValue.phase != "ready" {
          Button("Simulate storage error", systemImage: "externaldrive.badge.exclamationmark") {
            failForStorage(id: download.wrappedValue.id)
          }
        }
        Button("Delete", systemImage: "trash", role: .destructive) {
          remove(id: download.wrappedValue.id)
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.title3)
      }
    }
    .padding(.vertical, 5)
  }

  private var readyCount: Int {
    session.downloads.filter { $0.phase == "ready" }.count
  }

  private func resume(id: String) {
    update(id: id, phase: "running")
    Task { @MainActor in
      for step in 1...6 {
        try? await Task.sleep(for: .milliseconds(180))
        guard let index = session.downloads.firstIndex(where: { $0.id == id }) else {
          return
        }
        guard session.downloads[index].phase == "running" else { return }
        session.downloads[index].errorMessage = nil
        session.downloads[index].progress = min(
          1,
          session.downloads[index].progress + 0.12
        )
        if step == 6 && session.downloads[index].progress < 1 {
          session.downloads[index].progress = 1
        }
        if session.downloads[index].progress >= 1 {
          session.downloads[index].phase = "ready"
        }
      }
    }
  }

  private func update(id: String, phase: String) {
    guard let index = session.downloads.firstIndex(where: { $0.id == id }) else {
      return
    }
    session.downloads[index].phase = phase
  }

  private func failForStorage(id: String) {
    guard let index = session.downloads.firstIndex(where: { $0.id == id }) else {
      return
    }
    session.downloads[index].phase = "failed"
    session.downloads[index].errorMessage =
      "Insufficient storage · free space and retry"
  }

  private func remove(id: String) {
    withAnimation {
      session.downloads.removeAll { $0.id == id }
    }
  }
}
