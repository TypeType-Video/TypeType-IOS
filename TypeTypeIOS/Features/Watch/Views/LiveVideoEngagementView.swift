import SwiftUI

struct LiveVideoEngagementView: View {
  let likeCount: Int64
  let dislikeCount: Int64
  @StateObject private var viewModel: LiveVideoEngagementViewModel

  init(
    video: LiveVideoItem,
    stream: LivePlaybackStream?,
    allowsSubscription: Bool,
    service: LiveSubscriptionsServiceProtocol
  ) {
    likeCount = stream?.likeCount ?? -1
    dislikeCount = stream?.dislikeCount ?? -1
    _viewModel = StateObject(
      wrappedValue: LiveVideoEngagementViewModel(
        video: video,
        allowsSubscription: allowsSubscription,
        service: service
      )
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 14) {
        if likeCount >= 0 {
          metric(
            count: likeCount,
            symbol: "hand.thumbsup"
          )
        }
        if dislikeCount >= 0 {
          metric(
            count: dislikeCount,
            symbol: "hand.thumbsdown"
          )
        }
        Spacer(minLength: 0)
        if viewModel.canSubscribe {
          Button {
            Task { await viewModel.toggleSubscription() }
          } label: {
            if viewModel.isChanging {
              ProgressView()
                .controlSize(.small)
            } else {
              Text(
                viewModel.isSubscribed
                  ? "Subscribed"
                  : "Subscribe"
              )
            }
          }
          .buttonStyle(.borderedProminent)
          .tint(
            viewModel.isSubscribed
              ? DemoTheme.surface
              : DemoTheme.accent
          )
          .foregroundStyle(
            viewModel.isSubscribed
              ? Color.primary
              : Color.white
          )
          .disabled(viewModel.isLoading || viewModel.isChanging)
          .accessibilityIdentifier("live.video.subscribe")
        }
      }

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

  private func metric(
    count: Int64,
    symbol: String
  ) -> some View {
    let isLike = symbol == "hand.thumbsup"
    let formatted = LiveVideoMetadataFormatter.compactCount(count)
    return Label(
      formatted,
      systemImage: symbol
    )
    .font(.subheadline.weight(.medium))
    .foregroundStyle(.secondary)
    .accessibilityLabel(isLike ? "Likes" : "Dislikes")
    .accessibilityValue(formatted)
    .accessibilityIdentifier(
      isLike ? "live.video.likes" : "live.video.dislikes"
    )
  }
}
