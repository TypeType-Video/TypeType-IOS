import SwiftUI

struct DemoSearchStateView: View {
  let state: DemoSearchResultState
  let retry: () -> Void

  var body: some View {
    Group {
      switch state {
      case .loading:
        VStack(spacing: 14) {
          ProgressView()
          Text("Searching every configured service…")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      case .error:
        ContentUnavailableView {
          Label("Search unavailable", systemImage: "wifi.exclamationmark")
        } description: {
          Text("The mock request failed. Your query and filters are preserved.")
        } actions: {
          Button("Try again", action: retry)
            .buttonStyle(.borderedProminent)
        }
      case .normal:
        EmptyView()
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 70)
    .accessibilityIdentifier("demo.search.state.\(state.rawValue.lowercased())")
  }
}
