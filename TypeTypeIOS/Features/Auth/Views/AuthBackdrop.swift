import SwiftUI

struct AuthBackdrop: View {
  let isLight: Bool

  var body: some View {
    ZStack {
      baseColor
        .ignoresSafeArea()

      logoPattern
        .ignoresSafeArea()

      atmosphericGlow
        .ignoresSafeArea()

      vignette
        .ignoresSafeArea()
    }
  }

  private var baseColor: Color {
    isLight ? Color(red: 0.94, green: 0.96, blue: 0.97) : .black
  }

  private var logoPattern: some View {
    GeometryReader { proxy in
      Canvas { context, size in
        context.opacity = isLight ? 0.15 : 0.38
        let logo = context.resolve(Image("TypeTypeLogo"))
        let tile = min(max(size.width / 3.35, 112), 150)
        let horizontalStep = tile * 1.38
        let verticalStep = tile * 1.05

        for row in -2...Int(size.height / verticalStep) + 2 {
          let offset = row.isMultiple(of: 2) ? horizontalStep / 2 : 0
          for column in -2...Int(size.width / horizontalStep) + 2 {
            let origin = CGPoint(
              x: CGFloat(column) * horizontalStep + offset,
              y: CGFloat(row) * verticalStep
            )
            context.draw(
              logo,
              in: CGRect(
                x: origin.x,
                y: origin.y,
                width: tile,
                height: tile
              )
            )
          }
        }
      }
      .frame(
        width: proxy.size.width * 1.45,
        height: proxy.size.height * 1.32
      )
      .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
      .rotationEffect(.degrees(-12))
    }
  }

  private var atmosphericGlow: some View {
    ZStack {
      RadialGradient(
        colors: [
          Color.cyan.opacity(isLight ? 0.13 : 0.16),
          .clear,
        ],
        center: .topLeading,
        startRadius: 10,
        endRadius: 470
      )

      RadialGradient(
        colors: [
          Color.blue.opacity(isLight ? 0.09 : 0.12),
          .clear,
        ],
        center: .bottomTrailing,
        startRadius: 20,
        endRadius: 520
      )
    }
  }

  private var vignette: some View {
    RadialGradient(
      colors: [
        .clear,
        Color.black.opacity(isLight ? 0.08 : 0.72),
      ],
      center: .center,
      startRadius: 100,
      endRadius: 620
    )
  }
}
