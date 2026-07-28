import SwiftUI

extension LiveVideoQuickActionsModifier {
  var preview: some View {
    VStack(alignment: .leading, spacing: 10) {
      LiveRemoteImage(url: branding.thumbnailURL)
        .aspectRatio(16 / 9, contentMode: .fit)
      Text(branding.title)
        .font(.headline)
        .lineLimit(2)
        .padding([.horizontal, .bottom], 12)
    }
    .frame(width: 320)
    .background(DemoTheme.background)
  }

  private var branding: LiveVideoBranding {
    deArrowStore.branding(for: viewModel.video)
  }

  func presentQueueResult(
    _ result: LivePlaybackQueueMutationResult
  ) {
    let message: String
    switch result {
    case .added:
      message = "Added to playback queue"
    case .moved:
      message = "Moved to play next"
    case .alreadyQueued:
      message = "Already in playback queue"
    case .alreadyPlaying:
      message = "Already playing"
    case .noActivePlayback:
      message = "Start a video before building a queue"
    case .invalidVideo:
      message = "This video cannot be queued"
    }
    viewModel.presentMessage(message)
  }
}
