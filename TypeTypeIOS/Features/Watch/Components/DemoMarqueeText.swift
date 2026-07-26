import SwiftUI

struct DemoMarqueeText: View {
  let text: String
  let font: Font
  let color: Color
  @State private var textWidth: CGFloat = 0
  @State private var startedAt = Date.now

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        if textWidth > geometry.size.width + 8 {
          scrollingText
        } else {
          titleText
        }

        titleText
          .fixedSize()
          .hidden()
          .background {
            GeometryReader { measurement in
              Color.clear.preference(
                key: DemoMarqueeWidthKey.self,
                value: measurement.size.width
              )
            }
          }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .clipped()
    }
    .onPreferenceChange(DemoMarqueeWidthKey.self) {
      textWidth = $0
      startedAt = .now
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(text)
  }

  private var scrollingText: some View {
    TimelineView(.animation(minimumInterval: 1 / 45)) { context in
      HStack(spacing: gap) {
        titleText.fixedSize()
        titleText.fixedSize()
      }
      .offset(x: offset(at: context.date))
    }
    .accessibilityHidden(true)
  }

  private var titleText: some View {
    Text(text)
      .font(font)
      .foregroundStyle(color)
      .lineLimit(1)
  }

  private func offset(at date: Date) -> CGFloat {
    let distance = textWidth + gap
    let scrollDuration = max(4, Double(distance / 28))
    let leadingPause = 1.15
    let trailingPause = 0.8
    let cycle = leadingPause + scrollDuration + trailingPause
    let elapsed = max(0, date.timeIntervalSince(startedAt))
      .truncatingRemainder(dividingBy: cycle)
    guard elapsed > leadingPause else { return 0 }
    guard elapsed < leadingPause + scrollDuration else { return -distance }
    let progress = (elapsed - leadingPause) / scrollDuration
    return -distance * progress
  }

  private var gap: CGFloat {
    34
  }
}

private struct DemoMarqueeWidthKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}
