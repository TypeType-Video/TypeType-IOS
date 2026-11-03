import SwiftUI

struct LiveVideoCard: View {
  @Environment(\.livePrewarm) private var prewarm
  @State private var didPrewarm = false
  @State var showsActions = false
  @State private var pressTask: Task<Void, Never>?
  @State private var actionsPending = false
  @Environment(\.liveQuickActionsMenu) var quickActionsMenu
  @Environment(\.themePalette) var palette

  let video: LiveVideoItem
  @ObservedObject var deArrowStore: LiveDeArrowStore
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
      // Gestures on the view, not a Button: a long press added to a Button inside a ScrollView never fires.
      thumbnail
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .onLongPressGesture(minimumDuration: 0.45, perform: openActions) { pressing in
          pressTask?.cancel()
          guard pressing else {
            if actionsPending {
              actionsPending = false
              showsActions = true
            }
            return
          }
          // A scroll also starts with a press: only a finger that stays put prewarms.
          pressTask = Task {
            try? await Task.sleep(for: .milliseconds(120))
            if !Task.isCancelled { triggerPrewarm() }
          }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, action)
        .accessibilityAction(named: Text("More actions")) { showsActions = true }
        .accessibilityLabel("Open video \(branding.title)")
        .accessibilityHint("Opens video details")
        .accessibilityIdentifier("live.home.video.card.\(video.id)")

      HStack(alignment: .top, spacing: 10) {
        // Shorts from a search come without any channel: an empty circle there reads as a broken image.
        if video.uploaderAvatar != nil || !video.uploaderURL.isEmpty {
          channelAvatar
        }
        metadata
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .task { await deArrowStore.prepare(video) }
    .contentShape(Rectangle())
    .liveSettledPrefetch(video)
  }

  private func openActions() {
    guard quickActionsMenu != nil else { return }
    actionsPending = true
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }

  private func triggerPrewarm() {
    guard !didPrewarm else { return }
    didPrewarm = true
    prewarm?(video)
  }

  @EnvironmentObject private var watchProgress: LiveWatchProgressStore

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
      .liveThumbnailProgress(
        watchProgress.fraction(forVideoID: video.canonicalID)
      )
      .clipShape(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
  }
}
