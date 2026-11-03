import SwiftUI

struct LiveRelatedVideosSection: View, Equatable {
  let playerController: LivePlayerController
  let videos: [LiveVideoItem]
  let autoplayEnabled: Bool
  let deArrowStore: LiveDeArrowStore
  let dependencies: AppDependencies
  let onSelect: (LiveVideoItem) -> Void

  // Same reason as the comments below: a player tick redraws the page, not this list.
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.autoplayEnabled == rhs.autoplayEnabled
      && lhs.videos.map(\.canonicalID) == rhs.videos.map(\.canonicalID)
  }

  private var autoplayBinding: Binding<Bool> {
    Binding(
      get: { playerController.autoplayEnabled },
      set: { playerController.setAutoplay($0) }
    )
  }

  var body: some View {
    LiveHiddenVideosReader(dependencies.hiddenVideos) { hidden in
      list(hidden.visible(videos))
    }
  }

  @ViewBuilder
  private func list(_ videos: [LiveVideoItem]) -> some View {
    if !videos.isEmpty {
      VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .center) {
          Text("Up next")
            .font(.title3.weight(.bold))
          Spacer()
          HStack(spacing: 8) {
            Text("Autoplay")
              .font(.subheadline)
              .foregroundStyle(.secondary)
            Toggle("Autoplay", isOn: autoplayBinding)
              .toggleStyle(.switch)
              .controlSize(.small)
              .labelsHidden()
          }
          .accessibilityIdentifier("live.video.upnext.autoplay")
        }

        // A plain stack, like the comments below it: lazy rows rebuilt above the reader move the whole page.
        VStack(spacing: 14) {
          ForEach(videos) { video in
            LiveRelatedVideoRow(
              video: video,
              deArrowStore: deArrowStore,
              action: { onSelect(video) }
            )
            .liveVideoQuickActions(video: video, dependencies: dependencies)
          }
        }
      }
      .accessibilityIdentifier("live.player.related")
    }
  }
}

private struct LiveRelatedVideoRow: View {
  let video: LiveVideoItem
  @ObservedObject var deArrowStore: LiveDeArrowStore
  let action: () -> Void
  @EnvironmentObject private var watchProgress: LiveWatchProgressStore
  @Environment(\.liveQuickActionsMenu) private var quickActionsMenu
  @State private var showsActions = false

  var body: some View {
    content
      .accessibilityElement(children: .combine)
      .liveQuickActionsPress(showsActions: $showsActions, action: action)
      .overlay(alignment: .topTrailing) {
        if let quickActionsMenu {
          LiveDotMenu(isPresented: $showsActions) {
            quickActionsMenu
          }
          .accessibilityLabel("More actions for \(branding.title)")
        }
      }
      .task { await deArrowStore.prepare(video) }
  }

  private var content: some View {
    HStack(alignment: .top, spacing: 12) {
      LiveRemoteImage(url: branding.thumbnailURL)
        .frame(width: 148, height: 148 * 9 / 16)
        .clipped()
        .overlay(alignment: .bottomTrailing) {
          if !video.isLive {
            Text(
              LiveVideoMetadataFormatter.duration(video.duration)
            )
            .font(.caption2.monospacedDigit().weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.black.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(5)
          }
        }
        .liveThumbnailProgress(
          watchProgress.fraction(forVideoID: video.canonicalID)
        )
        .clipShape(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
        )

      VStack(alignment: .leading, spacing: 5) {
        Text(branding.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)

        Text(video.uploaderName)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Text(
          [
            LiveVideoMetadataFormatter.views(video.viewCount),
            LiveVideoMetadataFormatter.publication(video),
          ]
          .filter { !$0.isEmpty }
          .joined(separator: " · ")
        )
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.trailing, quickActionsMenu == nil ? 0 : 28)
    }
  }

  private var branding: LiveVideoBranding {
    deArrowStore.branding(for: video)
  }
}
