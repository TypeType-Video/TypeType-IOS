import SwiftUI

struct LivePipePipeImportSummary: View {
  let result: LivePipePipeRestoreResult

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Label("Import completed", systemImage: "checkmark.circle.fill")
        .foregroundStyle(.green)
      Text("\(result.history) history entries")
      Text("\(result.subscriptions) subscriptions")
      Text("\(result.playlists) playlists")
      Text("\(result.playlistVideos) playlist videos")
      Text("\(result.progress) progress entries")
      Text("\(result.searchHistory) searches")
    }
    .font(.caption)
  }
}
