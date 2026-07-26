import SwiftUI

struct LiveYouTubeImportCountsView: View {
  let title: String
  let counts: LiveYouTubeImportCounts

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.headline)
      Text("\(counts.subscriptions) subscriptions")
      Text("\(counts.playlists) playlists")
      Text("\(counts.playlistItems) playlist videos")
      Text("\(counts.favorites) favorites")
      Text("\(counts.watchLater) Watch later entries")
      Text("\(counts.history) history entries")
    }
    .font(.caption)
  }
}

struct LiveYouTubeImportReportView: View {
  let report: LiveYouTubeImportReport

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Label("Import completed", systemImage: "checkmark.circle.fill")
        .foregroundStyle(.green)
      result("Subscriptions", report.subscriptions)
      result("Playlists", report.playlists)
      result("Playlist videos", report.playlistItems)
      result("Favorites", report.favorites)
      result("Watch later", report.watchLater)
      result("History", report.history)
      ForEach(report.warnings, id: \.self) {
        Label($0, systemImage: "exclamationmark.triangle")
      }
      ForEach(report.errors, id: \.self) {
        Label($0, systemImage: "xmark.octagon")
          .foregroundStyle(.red)
      }
    }
    .font(.caption)
  }

  private func result(
    _ title: String,
    _ value: LiveYouTubeImportStats
  ) -> some View {
    Text(
      "\(title): \(value.imported) imported, "
        + "\(value.skipped) skipped, \(value.failed) failed"
    )
  }
}
