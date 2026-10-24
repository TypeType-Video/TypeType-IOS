import SwiftUI

struct LiveVideoEngagementView: View {
  let likeCount: Int64
  let dislikeCount: Int64
  let subscriberCount: Int64?
  let onChannel: (() -> Void)?
  private let video: LiveVideoItem
  @StateObject private var viewModel: LiveVideoEngagementViewModel

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
      // Views next to likes, like the Android player page.
      HStack(spacing: 14) {
        if video.viewCount > 0 {
          metric(count: video.viewCount, symbol: "eye")
        }
        if likeCount >= 0 {
          metric(count: likeCount, symbol: "hand.thumbsup")
        }
        if dislikeCount >= 0 {
          metric(count: dislikeCount, symbol: "hand.thumbsdown")
        }
        Spacer(minLength: 0)
      }

      channelBanner

      if let message = viewModel.message {
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
          .transition(.opacity)
      }
    }
    .task { await viewModel.prepare() }
    .accessibilityIdentifier("live.video.engagement")
  }

  /// Channel banner in the Android app style: avatar, name with verified
  /// seal, subscriber count, and the light Subscribe capsule on the right.
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
          if let subscriberCount {
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
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("live.video.channel.banner")
  }

  @ViewBuilder private var subscribeButton: some View {
    if viewModel.canSubscribe {
      Button {
        Task { await viewModel.toggleSubscription() }
      } label: {
        if viewModel.isChanging {
          ProgressView()
            .controlSize(.small)
        } else {
          Text(viewModel.isSubscribed ? "Subscribed" : "Subscribe")
        }
      }
      .buttonStyle(
        LiveChipButtonStyle(
          isFilled: !viewModel.isSubscribed,
          isActive: viewModel.isSubscribed
        )
      )
      .disabled(viewModel.isLoading || viewModel.isChanging)
      .accessibilityIdentifier("live.video.subscribe")
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
