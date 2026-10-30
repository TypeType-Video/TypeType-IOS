import SwiftUI

struct LiveDownloadsView: View {
  let dependencies: AppDependencies
  @ObservedObject var center: LiveDownloadCenter
  @State private var confirmsRemoveAll = false
  @Environment(\.liveToasts) private var toasts

  init(dependencies: AppDependencies, center: LiveDownloadCenter) {
    self.dependencies = dependencies
    self.center = center
  }

  var body: some View {
    Group {
      if center.visibleRecords.isEmpty {
        ContentUnavailableView(
          "No downloads",
          systemImage: "arrow.down.circle",
          description: Text("Download a video from its page to watch it without a connection.")
        )
        .liveThemedEmptyState()
      } else {
        list
      }
    }
    .navigationTitle("Downloads")
    .task { await center.activate() }
    .onChange(of: center.message) { _, message in
      guard let message else { return }
      toasts?.show(message, tone: .failure)
      center.message = nil
    }
    .accessibilityIdentifier("live.downloads.screen")
  }

  private var list: some View {
    List {
      LiveSection {
        HStack(spacing: 12) {
          LiveSettingsIconTile(icon: "internaldrive")
          VStack(alignment: .leading, spacing: 2) {
            Text(LiveDownloadTexts.size(center.storageUsage))
              .font(.headline.monospacedDigit())
            Text("On this device")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          Spacer()
          if !finished.isEmpty {
            Button("Delete all", role: .destructive) { confirmsRemoveAll = true }
              .font(.subheadline.weight(.semibold))
              .buttonStyle(.borderless)
              .alert("Delete all finished downloads?", isPresented: $confirmsRemoveAll) {
                Button("Cancel", role: .cancel) {}
                Button("Delete all", role: .destructive) { Task { await removeAll() } }
              } message: {
                Text("Downloads in progress are kept.")
              }
          }
        }
        .accessibilityElement(children: .combine)
      }
      section("In progress", records: inProgress)
      section("Available offline", records: ready)
      section("Not finished", records: stopped)
    }
    .liveGroupedList()
    .refreshable { await center.refresh() }
  }

  @ViewBuilder
  private func section(_ title: LocalizedStringKey, records: [LiveManagedDownload]) -> some View {
    if !records.isEmpty {
      LiveSection {
        ForEach(records) { record in
          LiveDownloadRow(
            record: record,
            artifactURL: center.artifactURL(for: record),
            onPlay: { play(record) },
            onCancel: { run { try await center.cancel(id: record.id) } },
            onRetry: { run { try await center.retry(id: record.id) } },
            onRemove: { run { try await center.remove(id: record.id) } }
          )
          .liveBareRow()
        }
      } header: {
        Text(title).liveSectionHeader()
      }
    }
  }

  private var inProgress: [LiveManagedDownload] { center.visibleRecords.filter(\.state.isActive) }
  private var ready: [LiveManagedDownload] { center.visibleRecords.filter { $0.state == .ready } }
  private var stopped: [LiveManagedDownload] {
    center.visibleRecords.filter { $0.state == .failed || $0.state == .cancelled }
  }
  private var finished: [LiveManagedDownload] { center.visibleRecords.filter { !$0.state.isActive } }

  private func play(_ record: LiveManagedDownload) {
    guard let url = center.artifactURL(for: record) else {
      center.message = String(localized: "The downloaded file is no longer available.")
      return
    }
    dependencies.playbackCoordinator.open(offline: LiveOfflinePlaybackItem(record: record, fileURL: url))
  }

  private func run(_ action: @escaping () async throws -> Void) {
    Task {
      do {
        try await action()
      } catch {
        center.message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
      }
    }
  }

  private func removeAll() async {
    for record in finished {
      do {
        try await center.remove(id: record.id)
      } catch {
        center.message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        return
      }
    }
    toasts?.show(String(localized: "Downloads deleted"))
  }
}
