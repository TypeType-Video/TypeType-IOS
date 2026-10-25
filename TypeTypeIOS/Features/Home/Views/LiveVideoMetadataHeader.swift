import SwiftUI

struct LiveVideoMetadataHeader: View {
  let video: LiveVideoItem
  let title: String
  let description: String?
  let subscriberCount: Int64?
  let onChannel: () -> Void
  let onSeekTimestamp: (TimeInterval) -> Void
  let onOpenURL: (URL) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.title2.weight(.bold))
        .textSelection(.enabled)

      .buttonStyle(.plain)
      .disabled(video.uploaderURL.isEmpty)

import SwiftUI

struct LiveVideoMetadataHeader: View {
  let video: LiveVideoItem
  let title: String
  let description: String?
  let subscriberCount: Int64?
  let onChannel: () -> Void
  let onSeekTimestamp: (TimeInterval) -> Void
  let onOpenURL: (URL) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.title2.weight(.bold))
        .textSelection(.enabled)

      .buttonStyle(.plain)
      .disabled(video.uploaderURL.isEmpty)

      if let description, !description.isEmpty {
        LiveVideoDescriptionCard(
          video: video,
          text: description,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
      }
    }
  }
}
