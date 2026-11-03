import SwiftUI

struct LiveIncrementalLoadingTrigger: View {
  let canLoadMore: Bool
  let isLoading: Bool
  let label: LocalizedStringKey
  let identifier: String
  let action: () -> Void
  @State private var isNearViewport = false

  var body: some View {
    if canLoadMore {
      ZStack {
        if isLoading {
          ProgressView(label)
            .font(.caption)
            .transition(.opacity)
        } else {
          Color.clear
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: isLoading ? 38 : 2)
      // Position, not appearance: in a plain stack the trigger appears with the page, long before it is reached.
      .onGeometryChange(for: Bool.self) { proxy in
        guard let viewport = proxy.bounds(of: .scrollView) else { return true }
        return viewport.maxY + Self.lookahead >= 0
      } action: { near in
        isNearViewport = near
        if near { request() }
      }
      .onChange(of: isLoading) { _, loading in
        if !loading, isNearViewport { request() }
      }
      .accessibilityIdentifier(identifier)
    }
  }

  private static let lookahead: CGFloat = 600

  private func request() {
    guard canLoadMore, !isLoading else { return }
    action()
  }
}
