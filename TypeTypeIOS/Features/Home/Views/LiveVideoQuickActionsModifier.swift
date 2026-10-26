import SwiftUI

struct LiveVideoQuickActionsModifier: ViewModifier {
  @StateObject var viewModel: LiveVideoQuickActionsViewModel
  @State var presentsDownload = false
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

  func body(content: Content) -> some View {
    content
      // The long-press menu is retired; the card renders a "…" button on
      // the title line and consumes this content as its menu.
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
      .alert(
        "Video",
        isPresented: Binding(
          get: { viewModel.message != nil },
          set: {
            if !$0 {
              viewModel.dismissMessage()
            }
          }
        )
      ) {
        Button("OK") { viewModel.dismissMessage() }
      } message: {
        Text(viewModel.message ?? "")
      }
      .sheet(isPresented: $presentsDownload) {
        LiveDownloadSheet(
          video: viewModel.video,
          dependencies: dependencies
        )
      }
  }
}

/// The vertical "⋮" menu glyph, drawn from shapes: SF Symbols in menu
/// labels get tinted by the accent colour, and their weight cannot be
/// controlled. Three dots in the title colour, guaranteed.
struct LiveDotsGlyph: View {
  var body: some View {
    VStack(spacing: 2.5) {
      ForEach(0..<3, id: \.self) { _ in
        Circle()
          .fill(Color.primary)
          .frame(width: 4, height: 4)
      }
    }
    .frame(width: 24, height: 24)
    .contentShape(Rectangle())
  }
}

/// The quick-actions menu content is handed to video cards via the
/// environment so the "…" button can live on the title line while the
/// long-press menu is retired.
private struct LiveQuickActionsMenuKey: EnvironmentKey {
  static let defaultValue: AnyView? = nil
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
