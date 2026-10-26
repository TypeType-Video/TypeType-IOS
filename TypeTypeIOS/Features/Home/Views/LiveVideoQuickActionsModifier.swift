import SwiftUI

struct LiveVideoQuickActionsModifier: ViewModifier {
  @StateObject var viewModel: LiveVideoQuickActionsViewModel
  /// Single sheet slot: the YouTube-style actions sheet and the download
  /// sheet swap through it (a second sheet over the first is refused).
  enum ActiveSheet: Int, Identifiable {
    case actions
    case download
    var id: Int { rawValue }
  }

  @State var activeSheet: ActiveSheet?
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
        LiveQuickActionsHandle(open: { activeSheet = .actions })
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
      .sheet(item: $activeSheet) { sheet in
        switch sheet {
        case .actions:
          ScrollView {
            VStack(alignment: .leading, spacing: 0) {
              quickActions
                .task {
                  async let actions: Void = viewModel.prepare()
                  async let branding: Void = deArrowStore.prepare(
                    viewModel.video
                  )
                  _ = await (actions, branding)
                }
            }
            .buttonStyle(LiveQuickActionRowStyle())
            .padding(.vertical, 8)
          }
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.visible)
          .presentationBackground(DemoTheme.surface)
        case .download:
          LiveDownloadSheet(
            video: viewModel.video,
            dependencies: dependencies
          )
        }
      }
  }
}

/// Handle the card's "…" button uses to open the actions sheet (handed
/// down via the environment; the long-press menu is retired).
struct LiveQuickActionsHandle {
  let open: () -> Void
}

private struct LiveQuickActionsMenuKey: EnvironmentKey {
  static let defaultValue: LiveQuickActionsHandle? = nil
}

extension EnvironmentValues {
  var liveQuickActionsMenu: LiveQuickActionsHandle? {
    get { self[LiveQuickActionsMenuKey.self] }
    set { self[LiveQuickActionsMenuKey.self] = newValue }
  }
}

/// YouTube-style action rows: large vertical list rows.
private struct LiveQuickActionRowStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.title3)
      .imageScale(.large)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.vertical, 14)
      .background(
        configuration.isPressed ? DemoTheme.groupedSurface : Color.clear
      )
      .contentShape(Rectangle())
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
