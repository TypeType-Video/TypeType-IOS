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
/// controlled.
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

/// Row style for the "…" popup: rows in the title colour — the default
/// button styling tinted every row with the accent — destructive stays red.
private struct LiveDotMenuRowStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(
        configuration.role == .destructive ? Color.red : Color.primary
      )
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .contentShape(Rectangle())
  }
}

/// The "…" menu: a plain button plus a popover. A SwiftUI `Menu` leaves its
/// label behind at the presentation position when it closes mid-scroll —
/// the button froze at a fixed screen spot instead of following the card.
struct LiveDotMenu<Content: View>: View {
  @State private var isPresented = false
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    Button {
      isPresented = true
    } label: {
      LiveDotsGlyph()
    }
    .popover(
      isPresented: $isPresented,
      // Anchor at the glyph's TOP edge: when the system flips the bubble
      // above the anchor near the bottom, the bubble ends at the glyph's
      // top and leaves the floating tab bar alone.
      attachmentAnchor: .point(.init(x: 0.5, y: 0.0))
    ) {
      VStack(alignment: .leading, spacing: 0) {
        content
      }
      .buttonStyle(LiveDotMenuRowStyle())
      .padding(8)
      .frame(width: 300, alignment: .leading)
      // Any tap inside fires the row's action AND closes the popup,
      // matching menu behaviour.
      .simultaneousGesture(TapGesture().onEnded { isPresented = false })
      .presentationCompactAdaptation(.popover)
      // No background or radius override: on the new design the system
      // presents popovers as Liquid Glass and spaces them from the floating
      // tab bar by itself.
    }
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
