import SwiftUI

struct LiveDownloadsView: View {
  @Environment(\.themePalette) private var palette
  let dependencies: AppDependencies
  @ObservedObject var center: LiveDownloadCenter
  let onlinePlaybackCoordinator: LivePlaybackCoordinator?
  @State private var playbackItem: LiveOfflinePlaybackItem?

  init(
    dependencies: AppDependencies,
    center: LiveDownloadCenter,
    onlinePlaybackCoordinator: LivePlaybackCoordinator? = nil
  ) {
    self.dependencies = dependencies
    self.center = center
    self.onlinePlaybackCoordinator = onlinePlaybackCoordinator
  }

  var body: some View {
    Group {
      if center.visibleRecords.isEmpty {
        ContentUnavailableView(
          "No downloads",
          systemImage: "arrow.down.circle",
          description: Text(
            "Downloads started from a video will remain available here."
          )
        ).liveThemedEmptyState()
      } else {
        List {
          ForEach(center.visibleRecords) { record in
            LiveManagedDownloadRow(
              record: record,
              artifactURL: center.artifactURL(for: record),
              onCancel: {
                Task {
                  do {
                    try await center.cancel(id: record.id)
                  } catch {
                    center.message = Self.message(for: error)
                  }
                }
              },
              onRetry: {
                Task {
                  do {
                    try await center.retry(id: record.id)
                  } catch {
                    center.message = Self.message(for: error)
                  }
                }
              },
              onRemove: {
                Task {
                  do {
                    try await center.remove(id: record.id)
                  } catch {
                    center.message = Self.message(for: error)
                  }
                }
              },
              onPlay: {
                guard let artifactURL = center.artifactURL(
                  for: record
                ) else {
                  center.message =
                    "The downloaded file is no longer available."
                  return
                }
                onlinePlaybackCoordinator?.controller?.pause()
                playbackItem = LiveOfflinePlaybackItem(
                  record: record,
                  fileURL: artifactURL
                )
              }
            )
          }
        }
          .liveThemedList()
        .refreshable {
          await center.refresh()
        }
        .safeAreaInset(edge: .bottom) {
          Text("Storage used: \(ByteCountFormatter.string(fromByteCount: center.storageUsage, countStyle: .file))")
            .font(.footnote.monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(palette.background)
        }
      }
    }
    .navigationTitle("Downloads")
        .task {
      await center.activate()
    }
    .alert(
      "Downloads",
      isPresented: Binding(
        get: { center.message != nil },
        set: {
          if !$0 { center.message = nil }
        }
      )
    ) {
      Button("OK") { center.message = nil }
    } message: {
      Text(center.message ?? "The download action failed.")
    }
    .fullScreenCover(item: $playbackItem) { item in
      LiveOfflinePlaybackView(item: item, dependencies: dependencies)
    }
    .accessibilityIdentifier("live.downloads.screen")
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? error.localizedDescription
  }
}
