import SwiftUI

struct LiveVideoQuickActionsModifier: ViewModifier {
  @Environment(\.themePalette) private var palette
  @StateObject var viewModel: LiveVideoQuickActionsViewModel
  @State var presentsDownload = false
  @State var presentsShareChoice = false
  @State var shareSheetURL: URL?
  @ObservedObject var deArrowStore: LiveDeArrowStore
  @ObservedObject var playbackCoordinator: LivePlaybackCoordinator
  let dependencies: AppDependencies
  let onOpenChannel: (() -> Void)?
  let removeLabel: String?
  let onRemove: (() -> Void)?

  init(
    video: LiveVideoItem,
    dependencies: AppDependencies,
    onOpenChannel: (() -> Void)?,
    removeLabel: String?,
    onRemove: (() -> Void)?
  ) {
    self.dependencies = dependencies
    deArrowStore = dependencies.deArrowStore
    playbackCoordinator = dependencies.playbackCoordinator
    _viewModel = StateObject(
      wrappedValue: LiveVideoQuickActionsViewModel(
        video: video,
        dependencies: dependencies
      )
    )
    self.onOpenChannel = onOpenChannel
    self.removeLabel = removeLabel
    self.onRemove = onRemove
  }

  /// Center glass card: green check, message, swipe-to-dismiss with a slow
  /// fade, plus the auto-dismiss timer.
  private func toastCard(_ message: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: "checkmark.circle.fill")
        .font(.title3.weight(.semibold))
        .foregroundStyle(palette.accent)
      Text(message)
        .font(.callout.weight(.semibold))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
    }
    .padding(.horizontal, 22)
    .padding(.vertical, 16)
    .transition(.opacity)
    .gesture(
      DragGesture(minimumDistance: 24)
        .onEnded { _ in
          withAnimation(.easeOut(duration: 0.6)) {
            viewModel.dismissMessage()
          }
        }
    )
    .task {
      try? await Task.sleep(for: .seconds(2.6))
      withAnimation(.easeOut(duration: 0.35)) {
        viewModel.dismissMessage()
      }
    }
  }

  func body(content: Content) -> some View {
    content
      // The card shows this content behind the "…" button on its title line.
      .environment(
        \.liveQuickActionsMenu,
        AnyView(
          quickActions
            .task {
              async let actions: Void = viewModel.prepare()
              async let branding: Void = deArrowStore.prepare(
                viewModel.video
              )
              _ = await (actions, branding)
            }
        )
      )
      // Center confirmation on Liquid Glass with a checkmark; it fades by
      // itself and can be swiped away, the swipe fading it slowly out.
      .overlay {
        if let message = viewModel.message {
          if #available(iOS 26.0, *) {
            toastCard(message)
              .glassEffect(.regular, in: .capsule)
          } else {
            toastCard(message)
              .background(.black.opacity(0.85), in: Capsule())
          }
        }
      }
      .animation(.easeIn(duration: 0.18), value: viewModel.message)
      .sheet(isPresented: $presentsDownload) {
        LiveDownloadSheet(
          video: viewModel.video,
          dependencies: dependencies
        )
      }
      .popover(
        isPresented: $presentsShareChoice,
        attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
        arrowEdge: .top
      ) {
        LiveShareChoiceCard(
          hasOriginal: LiveShareURLBuilder.original(
            sourceURL: viewModel.video.url
          ) != nil,
          onTypeType: {
            shareSheetURL = LiveShareURLBuilder.video(
              serverURL: dependencies.serverStore.selectedServer()?.baseURL,
              sourceURL: viewModel.video.url
            )
          },
          onOriginal: {
            shareSheetURL = LiveShareURLBuilder.original(
              sourceURL: viewModel.video.url
            )
          },
          onCancel: { presentsShareChoice = false }
        )
      }
      .sheet(isPresented: shareSheetBinding) {
        if let shareSheetURL {
          LiveShareActivityView(url: shareSheetURL)
        }
      }
  }

  private var shareSheetBinding: Binding<Bool> {
    Binding(
      get: { shareSheetURL != nil },
      set: { if !$0 { shareSheetURL = nil } }
    )
  }
}

extension EnvironmentValues {
  var liveQuickActionsMenu: AnyView? {
    get { self[LiveQuickActionsMenuKey.self] }
    set { self[LiveQuickActionsMenuKey.self] = newValue }
  }
}

extension View {
  func liveVideoQuickActions(
    video: LiveVideoItem,
    dependencies: AppDependencies,
    onOpenChannel: (() -> Void)? = nil,
    removeLabel: String? = nil,
    onRemove: (() -> Void)? = nil
  ) -> some View {
    modifier(
      LiveVideoQuickActionsModifier(
        video: video,
        dependencies: dependencies,
        onOpenChannel: onOpenChannel,
        removeLabel: removeLabel,
        onRemove: onRemove
      )
    )
  }
}
