import SwiftUI

struct TypeTypeSkeletonList: View {
  @Environment(\.themePalette) private var palette
  enum Layout {
    case cards
    case rows
    case settings
  }

  var layout = Layout.cards
  var count = 6
  var scrolls = true

  var body: some View {
    if scrolls {
      ScrollView { grid.padding(16) }
        .scrollDisabled(true)
        .background(palette.background)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    } else {
      grid
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
  }

  private var grid: some View {
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: layout == .cards ? 280 : 400), spacing: 18, alignment: .top)],
        alignment: .leading,
        spacing: 22
      ) {
        ForEach(0..<count, id: \.self) { _ in
          switch layout {
          case .cards: card
          case .rows: row
          case .settings: setting
          }
        }
      }
  }

  private var card: some View {
    VStack(alignment: .leading, spacing: 10) {
      TypeTypeSkeleton(cornerRadius: 14)
        .aspectRatio(16 / 9, contentMode: .fit)
      HStack(alignment: .top, spacing: 10) {
        TypeTypeSkeleton(cornerRadius: 18).frame(width: 36, height: 36)
        lines
      }
    }
  }

  private var row: some View {
    HStack(alignment: .top, spacing: 12) {
      TypeTypeSkeleton(cornerRadius: 14)
        .frame(width: 160, height: 90)
      lines
    }
  }

  private var setting: some View {
    VStack(alignment: .leading, spacing: 8) {
      TypeTypeSkeleton(cornerRadius: 6)
        .frame(width: 150, height: 12)
      TypeTypeSkeleton(cornerRadius: 6)
        .frame(width: 230, height: 10)
    }
    .padding(.vertical, 10)
  }

  private var lines: some View {
    VStack(alignment: .leading, spacing: 6) {
      bar(1, height: 12)
      bar(0.7, height: 12)
      bar(0.45, height: 10)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func bar(_ fraction: CGFloat, height: CGFloat) -> some View {
    GeometryReader { proxy in
      TypeTypeSkeleton(cornerRadius: 4).frame(width: proxy.size.width * fraction)
    }
    .frame(height: height)
  }
}
