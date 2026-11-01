import SwiftUI

struct LiveVideoQuickActionsModifier: ViewModifier {
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
  let onNotInterested: (() -> Void)?

  init(
    video: LiveVideoItem,
    dependencies: AppDependencies,
    onOpenChannel: (() -> Void)?,
    removeLabel: String?,
    onRemove: (() -> Void)?,
    onNotInterested: (() -> Void)?
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
    self.onNotInterested = onNotInterested
  }

  func body(content: Content) -> some View {
    content
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
    onRemove: (() -> Void)? = nil,
    onNotInterested: (() -> Void)? = nil
  ) -> some View {
    modifier(
      LiveVideoQuickActionsModifier(
        video: video,
        dependencies: dependencies,
        onOpenChannel: onOpenChannel,
        removeLabel: removeLabel,
        onRemove: onRemove,
        onNotInterested: onNotInterested
      )
    )
  }
}
