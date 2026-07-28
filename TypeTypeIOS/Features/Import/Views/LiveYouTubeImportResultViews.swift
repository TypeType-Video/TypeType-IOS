import SwiftUI

struct LiveYouTubeImportCountsView: View {
  let title: String
  let counts: LiveYouTubeImportCounts

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(title).font(.headline)
      count("Subscriptions", counts.subscriptions)
      count("Playlists", counts.playlists)
      count("Playlist videos", counts.playlistItems)
      count("Favorites", counts.favorites)
      count("Watch later", counts.watchLater)
      count("History", counts.history)
    }
    .font(.caption)
  }

  private func count(_ title: String, _ value: Int) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(value, format: .number)
        .monospacedDigit()
        .foregroundStyle(.secondary)
    }
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
