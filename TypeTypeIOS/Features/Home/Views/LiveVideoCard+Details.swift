import SwiftUI

extension LiveVideoCard {
  @ViewBuilder
  var channelAvatar: some View {
    if let onChannel, !video.uploaderURL.isEmpty {
      Button(action: onChannel) {
        avatar
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Open channel \(video.uploaderName)")
    } else {
      avatar
        .accessibilityHidden(true)
    }
  }

  var avatar: some View {
    LiveRemoteImage(url: video.uploaderAvatar)
      .frame(width: 36, height: 36)
      .clipShape(Circle())
      .overlay {
        Circle().stroke(palette.separator.opacity(0.35))
      }
  }

  var metadata: some View {
    VStack(alignment: .leading, spacing: 4) {
      Button(action: action) {
        Text(branding.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.trailing, quickActionsMenu == nil ? 0 : 36)

      if let onChannel {
      Button(action: onChannel) {
        channelName
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Open channel \(video.uploaderName)")
      } else {
        channelName
      }

      Text(detailText)
        .font(.caption2.weight(.medium))
        .foregroundStyle(Color.primary.opacity(0.65))
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    // Anchored to the corner, not the title: DeArrow swaps titles after load.
    .overlay(alignment: .topTrailing) {
      if let quickActionsMenu {
        LiveDotMenu(isPresented: $showsActions) {
          quickActionsMenu
        }
        .accessibilityLabel("More actions for \(branding.title)")
      }
    }
  }

  var channelName: some View {
    HStack(spacing: 4) {
      Text(video.uploaderName)
        .lineLimit(1)
      if video.uploaderVerified {
        Image(systemName: "checkmark.seal.fill")
          .font(.caption2)
          .accessibilityLabel("Verified")
      }
    }
    .font(.caption.weight(.medium))
    .foregroundStyle(Color.primary.opacity(0.65))
  }

  @ViewBuilder
  var durationBadge: some View {
    if !video.isLive, video.duration > 0 {
      Text(LiveVideoMetadataFormatter.duration(video.duration))
        .font(.caption2.monospacedDigit().weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.black.opacity(0.84), in: RoundedRectangle(cornerRadius: 5))
        .padding(7)
        .accessibilityHidden(true)
    }
  }

  @ViewBuilder
  var stateBadges: some View {
    HStack(spacing: 5) {
      if video.isLive {
        badge("LIVE", color: .red)
      } else if video.isPostLive {
        badge("STREAMED", color: .black.opacity(0.72))
      }
      if video.requiresMembership {
        badge("MEMBERS", color: palette.accent)
      }
    }
    .padding(7)
    .accessibilityHidden(true)
  }

  func badge(_ text: LocalizedStringKey, color: Color) -> some View {
    Text(text)
      .font(.caption2.weight(.bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(color, in: RoundedRectangle(cornerRadius: 5))
  }

  var detailText: String {
    [
      LiveVideoMetadataFormatter.views(video.viewCount),
      LiveVideoMetadataFormatter.publication(video),
    ]
    .filter { !$0.isEmpty }
    .joined(separator: " · ")
  }

  var branding: LiveVideoBranding {
    deArrowStore.branding(for: video)
  }
}
