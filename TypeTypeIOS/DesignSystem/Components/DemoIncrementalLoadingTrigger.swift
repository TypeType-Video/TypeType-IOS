import SwiftUI

struct DemoIncrementalLoadingTrigger: View {
  let canLoadMore: Bool
  let isLoading: Bool
  let label: String
  let identifier: String
  let action: () -> Void

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
      .onAppear {
        if !isLoading {
          action()
        }
      }
      .accessibilityIdentifier(identifier)
    }
  }
}
