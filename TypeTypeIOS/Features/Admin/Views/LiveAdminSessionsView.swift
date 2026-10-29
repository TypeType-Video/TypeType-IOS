import SwiftUI

struct LiveAdminSessionsView: View {
  @StateObject private var viewModel: LiveAdminSessionsViewModel

  init(service: LiveAdminServiceProtocol) {
    _viewModel = StateObject(
      wrappedValue: LiveAdminSessionsViewModel(service: service)
    )
  }

  var body: some View {
    content
      .navigationTitle("Active sessions")
      .navigationBarTitleDisplayMode(.inline)
      .task { await viewModel.prepare() }
      .accessibilityIdentifier("live.admin.sessions")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .settings, count: 8)
    case let .failed(message):
      ContentUnavailableView {
        Label("Sessions unavailable", systemImage: "network.slash")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      if viewModel.sessions.isEmpty {
        ContentUnavailableView(
          "No active sessions",
          systemImage: "dot.radiowaves.left.and.right"
        ).liveThemedEmptyState()
      } else {
        List(viewModel.sessions) { session in
          LiveAdminSessionRow(session: session)
        }
        .listStyle(.plain)
        .refreshable { await viewModel.reload() }
      }
    }
  }
}
