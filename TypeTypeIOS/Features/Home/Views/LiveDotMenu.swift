import SwiftUI

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

struct LiveDotMenuRowStyle: ButtonStyle {
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
      .frame(maxHeight: 460)
      .simultaneousGesture(TapGesture().onEnded { isPresented = false })
      .presentationCompactAdaptation(.popover)
    }
  }
}

struct LiveQuickActionsMenuKey: EnvironmentKey {
  static let defaultValue: AnyView? = nil
}
