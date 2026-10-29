import SwiftUI

extension DemoWatchActionsView {
  func actionButton(
    _ title: String,
    systemImage: String,
    active: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      actionLabel(title, systemImage: systemImage, active: active)
    }
    .buttonStyle(.plain)
  }

  func actionLabel(
    _ title: String,
    systemImage: String,
    active: Bool
  ) -> some View {
    Label(title, systemImage: systemImage)
      .font(.subheadline.weight(.medium))
      .foregroundStyle(active ? Color.white : Color.primary)
      .padding(.horizontal, 14)
      .frame(height: 42)
      .background(
        active
          ? Color.accentColor
          : palette.surface
      )
      .clipShape(Capsule())
  }

  func showToast(_ message: String) {
    toastMessage = message
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(2))
      if toastMessage == message {
        toastMessage = nil
      }
    }
  }

  var isFavorite: Bool {
    session.favoriteVideoIDs.contains(video.id)
  }

  var isInWatchLater: Bool {
    session.watchLaterVideoIDs.contains(video.id)
  }

  var isVideoBlocked: Bool {
    session.blockedVideoIDs.contains(video.id)
  }

  var isChannelBlocked: Bool {
    session.blockedChannelNames.contains(video.channel)
  }

  var isDownloaded: Bool {
    session.downloads.contains { $0.id == video.id && $0.progress >= 1 }
  }
}
