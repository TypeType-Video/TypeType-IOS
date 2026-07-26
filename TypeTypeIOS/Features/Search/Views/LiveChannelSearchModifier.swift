import SwiftUI

struct LiveChannelSearchModifier: ViewModifier {
  @ObservedObject var viewModel: LiveChannelViewModel

  @ViewBuilder
  func body(content: Content) -> some View {
    if supportsSearch {
      content
        .searchable(
          text: $viewModel.query,
          placement: .navigationBarDrawer(displayMode: .always),
          prompt: "Search this channel"
        )
        .submitLabel(.search)
        .onSubmit(of: .search) {
          Task { await viewModel.submitChannelSearch() }
        }
        .onChange(of: viewModel.query) { _, query in
          guard query.isEmpty, !viewModel.submittedQuery.isEmpty else {
            return
          }
          Task { await viewModel.clearChannelSearch() }
        }
    } else {
      content
    }
  }

  private var supportsSearch: Bool {
    viewModel.selectedTab == .videos
      && LiveChannelRequestURLBuilder.isYouTube(viewModel.channelURL)
  }
}
