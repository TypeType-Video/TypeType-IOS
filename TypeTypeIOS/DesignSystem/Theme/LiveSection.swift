import SwiftUI

struct LiveSection<Content: View, Header: View, Footer: View>: View {
  private let content: Content
  private let header: Header
  private let footer: Footer

  init(
    @ViewBuilder content: () -> Content,
    @ViewBuilder header: () -> Header,
    @ViewBuilder footer: () -> Footer
  ) {
    self.content = content()
    self.header = header()
    self.footer = footer()
  }

  var body: some View {
    Section {
      content.liveRowBackground()
    } header: {
      slot(header, top: 16, bottom: 8)
    } footer: {
      slot(footer, top: 8, bottom: 8)
    }
  }

  @ViewBuilder
  private func slot<Slot: View>(_ view: Slot, top: CGFloat, bottom: CGFloat) -> some View {
    if Slot.self == EmptyView.self {
      view
    } else {
      view
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, top)
        .padding(.bottom, bottom)
        .listRowInsets(EdgeInsets())
        .background(DemoThemeBackground())
    }
  }
}

extension LiveSection where Footer == EmptyView {
  init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) {
    self.init(content: content, header: header, footer: { EmptyView() })
  }
}

extension LiveSection where Header == EmptyView {
  init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
    self.init(content: content, header: { EmptyView() }, footer: footer)
  }
}

extension LiveSection where Header == EmptyView, Footer == EmptyView {
  init(@ViewBuilder content: () -> Content) {
    self.init(content: content, header: { EmptyView() }, footer: { EmptyView() })
  }
}

extension View {
  func liveRowBackground() -> some View {
    listRowBackground(ThemeRowFill())
  }
}

struct ThemeRowFill: View {
  @Environment(\.themePalette) private var palette

  var body: some View {
    palette.rowBackground
  }
}
