import SwiftUI

struct LiveCommunityPostCard: View {
  @Environment(\.themePalette) private var palette
  let post: LiveCommunityPost
  var nested = false
  let onOpenVideo: (String) -> Void
  let onOpenURL: (URL) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      header
      if !post.displayText.isEmpty {
        InteractiveText(text: post.displayText, font: nested ? .subheadline : .body, lineLimit: nil, onOpenURL: onOpenURL)
          .textSelection(.enabled)
      }
      images
      if let poll = post.poll { pollView(poll) }
      if let video = post.video { videoView(video) }
      if let shared = post.sharedPost, !nested {
        LiveCommunityPostCard(post: shared.post, nested: true, onOpenVideo: onOpenVideo, onOpenURL: onOpenURL)
      }
      if !nested { footer }
    }
    .padding(nested ? 12 : 14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  private var header: some View {
    HStack(spacing: 10) {
      LiveRemoteImage(url: LiveImageURLResolver.resolve(post.authorAvatarURL))
        .frame(width: nested ? 26 : 34, height: nested ? 26 : 34)
        .clipShape(Circle())
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 1) {
        Text(verbatim: post.authorName)
          .font(.subheadline.weight(.semibold))
        if !post.publishedDisplay.isEmpty {
          Text(verbatim: post.publishedDisplay)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var images: some View {
    let urls = post.images.compactMap { LiveImageURLResolver.resolve($0) }
    if urls.count == 1, let url = urls.first {
      LiveRemoteImage(url: url)
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityLabel("Image of the post")
    } else if urls.count > 1 {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(Array(urls.enumerated()), id: \.offset) { _, url in
            LiveRemoteImage(url: url)
              .frame(width: 220, height: 220)
              .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          }
        }
      }
      .accessibilityLabel("\(urls.count) images of the post")
    }
  }

  private func pollView(_ poll: LiveCommunityPost.Poll) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(Array(poll.choices.enumerated()), id: \.offset) { _, choice in
        Text(verbatim: choice)
          .font(.subheadline)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
      if !poll.textualVoteCount.isEmpty {
        Text(verbatim: poll.textualVoteCount)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Poll")
  }

  private func videoView(_ video: LiveCommunityPost.Video) -> some View {
    Button {
      onOpenVideo(video.url)
    } label: {
      HStack(spacing: 10) {
        LiveRemoteImage(url: LiveImageURLResolver.resolve(video.thumbnailURL))
          .frame(width: 128, height: 72)
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        Text(verbatim: video.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(3)
          .multilineTextAlignment(.leading)
        Spacer(minLength: 0)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text("Play \(video.title)"))
  }

  private var footer: some View {
    HStack(spacing: 16) {
      if !post.textualLikeCount.isEmpty {
        Label { Text(verbatim: post.textualLikeCount) } icon: { Image(systemName: "hand.thumbsup") }
      }
      if !post.textualCommentCount.isEmpty {
        Label { Text(verbatim: post.textualCommentCount) } icon: { Image(systemName: "text.bubble") }
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
}
