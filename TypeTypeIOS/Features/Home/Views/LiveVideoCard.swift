import SwiftUI

struct LiveVideoCard: View {
  let video: LiveVideoItem
  @ObservedObject private var deArrowStore: LiveDeArrowStore
  let onChannel: (() -> Void)?
  let action: () -> Void

  init(
    video: LiveVideoItem,
    deArrowStore: LiveDeArrowStore,
    onChannel: (() -> Void)? = nil,
    action: @escaping () -> Void
  ) {
    self.video = video
    self.deArrowStore = deArrowStore
    self.onChannel = onChannel
    self.action = action
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Button(action: action) {
        thumbnail
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("live.home.video.card.\(video.id)")

      HStack(alignment: .top, spacing: 10) {
        channelAvatar
        metadata
      }
    }
    .task { await deArrowStore.prepare(video) }
    .contentShape(Rectangle())
  }

  private var thumbnail: some View {
    LiveRemoteImage(url: branding.thumbnailURL)
      .frame(maxWidth: .infinity)
      .aspectRatio(16 / 9, contentMode: .fit)
      .clipped()
      .overlay(alignment: .bottomTrailing) {
        durationBadge
      }
      .overlay(alignment: .topLeading) {
        stateBadges
      }
      .clipShape(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
  }

  @ViewBuilder
  private var channelAvatar: some View {
    if let onChannel {
      Button(action: onChannel) {
        avatar
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Open \(video.uploaderName)")
    } else {
      avatar
        .accessibilityHidden(true)
    }
  }

  private var avatar: some View {
    LiveRemoteImage(url: video.uploaderAvatar)
      .frame(width: 36, height: 36)
      .clipShape(Circle())
      .overlay {
        Circle().stroke(DemoTheme.separator.opacity(0.35))
      }
  }

  private var metadata: some View {
    VStack(alignment: .leading, spacing: 4) {
      Button(action: action) {
        Text(branding.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
      }
      .buttonStyle(.plain)

      if let onChannel {
        Button(action: onChannel) {
          channelName
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(video.uploaderName)")
      } else {
        channelName
      }

      Text(detailText)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var channelName: some View {
    HStack(spacing: 4) {
      Text(video.uploaderName)
        .lineLimit(1)
      if video.uploaderVerified {
        Image(systemName: "checkmark.seal.fill")
          .font(.caption2)
          .accessibilityLabel("Verified")
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }

  @ViewBuilder
  private var durationBadge: some View {
    if !video.isLive {
      Text(LiveVideoMetadataFormatter.duration(video.duration))
        .font(.caption2.monospacedDigit().weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.black.opacity(0.84), in: RoundedRectangle(cornerRadius: 5))
        .padding(7)
    }
  }

  @ViewBuilder
  private var stateBadges: some View {
    HStack(spacing: 5) {
      if video.isLive {
        badge("LIVE", color: .red)
      } else if video.isPostLive {
        badge("STREAMED", color: .black.opacity(0.72))
      }
      if video.requiresMembership {
        badge("MEMBERS", color: DemoTheme.accent)
      }
    }
    .padding(7)
  }

  private func badge(_ text: String, color: Color) -> some View {
    Text(text)
      .font(.caption2.weight(.bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(color, in: RoundedRectangle(cornerRadius: 5))
  }

  private var detailText: String {
    [
      LiveVideoMetadataFormatter.views(video.viewCount),
      LiveVideoMetadataFormatter.publication(video),
    ]
    .filter { !$0.isEmpty }
    .joined(separator: " · ")
  }

  private var branding: LiveVideoBranding {
    deArrowStore.branding(for: video)
  }
}
