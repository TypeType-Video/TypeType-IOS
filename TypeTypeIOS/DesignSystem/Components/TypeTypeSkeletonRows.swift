import SwiftUI

struct TypeTypeSkeletonRows: View {
  enum Leading: Equatable {
    case none
    case circle(diameter: CGFloat)
    case rectangle(width: CGFloat, height: CGFloat)
  }

  var leading = Leading.none
  var count = 6

  private static let titleWidths: [CGFloat] = [0.62, 0.48, 0.7, 0.55, 0.66, 0.5]

  var body: some View {
    ForEach(0..<count, id: \.self) { index in
      row(index)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
        .accessibilityHidden(index > 0)
    }
  }

  private func row(_ index: Int) -> some View {
    HStack(spacing: 12) {
      leadingShape
      VStack(alignment: .leading, spacing: 8) {
        bar(Self.titleWidths[index % Self.titleWidths.count], height: 13)
        bar(0.34, height: 10)
      }
    }
    .padding(.vertical, 4)
  }

  @ViewBuilder
  private var leadingShape: some View {
    switch leading {
    case .none:
      EmptyView()
    case let .circle(diameter):
      TypeTypeSkeleton(cornerRadius: diameter / 2).frame(width: diameter, height: diameter)
    case let .rectangle(width, height):
      TypeTypeSkeleton(cornerRadius: min(8, height / 4)).frame(width: width, height: height)
    }
  }

  private func bar(_ fraction: CGFloat, height: CGFloat) -> some View {
    GeometryReader { proxy in
      TypeTypeSkeleton(cornerRadius: height / 2).frame(width: proxy.size.width * fraction)
    }
    .frame(height: height)
  }
}

struct TypeTypeSkeletonGroupedList: View {
  var leading = TypeTypeSkeletonRows.Leading.none
  var count = 6

  var body: some View {
    List {
      LiveSection {
        TypeTypeSkeletonRows(leading: leading, count: count)
      }
    }
    .liveGroupedList()
    .scrollDisabled(true)
  }
}
