import SwiftUI

struct WatchMetaRow: View {
  let stream: WatchStream

  var body: some View {
    HStack(spacing: 10) {
      Text("\(formatViews(stream.viewCount)) views")
      Text("•")
      Text(stream.uploadDate)
      Text("•")
      Text(formatDuration(stream.duration))
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }

  private func formatDuration(_ total: Int64) -> String {
    let minutes = total / 60
    let seconds = total % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  private func formatViews(_ views: Int64) -> String {
    if views >= 1_000_000 { return String(format: "%.1fM", Double(views) / 1_000_000.0) }
    if views >= 1_000 { return String(format: "%.1fK", Double(views) / 1_000.0) }
    return "\(views)"
  }
}
