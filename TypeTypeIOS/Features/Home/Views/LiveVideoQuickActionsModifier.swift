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

  /// Center glass card: green check, message, swipe-to-dismiss with a slow
  /// fade, plus the auto-dismiss timer.
  private func toastCard(_ message: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: "checkmark.circle.fill")
        .font(.title3.weight(.semibold))
        .foregroundStyle(DemoTheme.accent)
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
  @State private var anchorFrame: CGRect?
  @State private var opensUpward = true
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    Button {
      // The side is picked at open time from the button's screen position:
      // in the upper half the bubble opens downward, otherwise upward, so
      // it always fits between the screen edges.
      if let frame = anchorFrame {
        opensUpward = frame.midY > UIScreen.main.bounds.height / 2
      }
      isPresented = true
    } label: {
      LiveDotsGlyph()
    }
    .onGeometryChange(for: CGRect.self) { proxy in
      proxy.frame(in: .global)
    } action: { frame in
      anchorFrame = frame
    }
    .popover(
      isPresented: $isPresented,
      attachmentAnchor: .point(.init(x: 0.5, y: 0.0)),
      arrowEdge: opensUpward ? .bottom : .top
    ) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          content
        }
      }
      .buttonStyle(LiveDotMenuRowStyle())
      .padding(8)
      .frame(width: 300, alignment: .leading)
      // Never taller than the screen can show: excess rows scroll.
      .frame(maxHeight: 460)
      // Any tap inside fires the row's action AND closes the popup,
      // matching menu behaviour.
      .simultaneousGesture(TapGesture().onEnded { isPresented = false })
      .presentationCompactAdaptation(.popover)
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
