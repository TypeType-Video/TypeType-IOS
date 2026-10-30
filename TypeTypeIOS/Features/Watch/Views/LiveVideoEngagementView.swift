import SwiftUI

struct LiveVideoEngagementView: View {
  let likeCount: Int64
  let dislikeCount: Int64
  let subscriberCount: Int64?
  let onChannel: (() -> Void)?
  private let video: LiveVideoItem
  @StateObject private var viewModel: LiveVideoEngagementViewModel
  @Environment(\.liveWatchExtrasEnabled) private var extrasEnabled

  init(
    video: LiveVideoItem,
    stream: LivePlaybackStream?,
    allowsSubscription: Bool,
    service: LiveSubscriptionsServiceProtocol,
    subscriberCount: Int64? = nil,
    onChannel: (() -> Void)? = nil
  ) {
    self.video = video
    likeCount = stream?.likeCount ?? -1
    dislikeCount = stream?.dislikeCount ?? -1
    self.subscriberCount = subscriberCount
    self.onChannel = onChannel
    _viewModel = StateObject(
      wrappedValue: LiveVideoEngagementViewModel(
        video: video,
        allowsSubscription: allowsSubscription,
        service: service
      )
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      statsRow

      channelBanner

      if let message = viewModel.message {
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
          .transition(.opacity)
      }
    }
    .task(id: extrasEnabled) {
      guard extrasEnabled else { return }
      await viewModel.prepare()
    }
    .accessibilityIdentifier("live.video.engagement")
  }

  private var statsRow: some View {
    HStack(spacing: 8) {
      if video.viewCount >= 0 {
        metric(count: video.viewCount, symbol: "eye.fill")
          .liveGlassChip()
      }
      if likeCount >= 0 {
        metric(count: likeCount, symbol: "hand.thumbsup.fill")
          .liveGlassChip()
      }
      if dislikeCount >= 0 {
        metric(count: dislikeCount, symbol: "hand.thumbsdown.fill")
          .liveGlassChip()
      }
      Spacer(minLength: 0)
    }
    .accessibilityIdentifier("live.video.stats")
  }

  private var channelBanner: some View {
    Button(action: { onChannel?() }) {
      HStack(spacing: 12) {
        LiveRemoteImage(url: video.uploaderAvatar)
          .frame(width: 44, height: 44)
          .clipShape(Circle())
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 4) {
            Text(video.uploaderName)
              .font(.headline)
              .foregroundStyle(.primary)
            if video.uploaderVerified {
              Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(.blue)
                .accessibilityLabel("Verified")
            }
          }
          if let subscriberCount, subscriberCount > 0 {
            Text(LiveVideoMetadataFormatter.subscribers(subscriberCount))
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .accessibilityIdentifier("live.video.channel.subscribers")
          }
        }
        Spacer(minLength: 12)
        subscribeButton
      }
      .contentShape(Rectangle())
      .padding(12)
      .liveGlassCard(cornerRadius: 14)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("live.video.channel.banner")
  }

  @ViewBuilder private var subscribeButton: some View {
    if viewModel.canSubscribe {
      if viewModel.isChanging {
        ProgressView()
          .controlSize(.small)
          .frame(width: 44, height: 34)
      } else if viewModel.isSubscribed {
        Menu {
          Button("Unsubscribe", systemImage: "person.badge.minus", role: .destructive) {
            Task { await viewModel.toggleSubscription() }
          }
        } label: {
          HStack(spacing: 6) {
            Image(systemName: "checkmark")
            Image(systemName: "chevron.down")
              .font(.caption.weight(.bold))
          }
          .font(.body.weight(.semibold))
          .foregroundStyle(.primary)
          .padding(.horizontal, 14)
          .frame(height: 34)
          .background(.quaternary, in: Capsule())
        }
        .disabled(viewModel.isLoading)
        .accessibilityLabel(Text("Subscribed"))
        .accessibilityIdentifier("live.video.subscribe")
      } else {
        Button("Subscribe") {
          Task { await viewModel.toggleSubscription() }
        }
        .buttonStyle(LiveChipButtonStyle(isFilled: true, isActive: true))
        .disabled(viewModel.isLoading)
        .accessibilityIdentifier("live.video.subscribe")
      }
    }
  }

  private func metric(
    count: Int64,
    symbol: String
  ) -> some View {
    let formatted = LiveVideoMetadataFormatter.compactCount(count)
    return Label {
      Text(formatted)
        .foregroundStyle(.primary)
    } icon: {
      Image(systemName: symbol)
        .foregroundStyle(.secondary)
    }
    .font(.subheadline)
  }
}
