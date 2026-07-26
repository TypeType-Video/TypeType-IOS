import Foundation
import SwiftUI

struct LiveChannelControlsView: View {
  @ObservedObject var viewModel: LiveChannelViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if isYouTube {
        Picker("Channel section", selection: tabBinding) {
          ForEach(LiveChannelTab.allCases) { tab in
            Text(tab.title).tag(tab)
          }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("live.channel.tabs")
      }

      if viewModel.selectedTab == .videos,
        viewModel.submittedQuery.isEmpty {
        Picker("Video order", selection: sortBinding) {
          ForEach(LiveChannelSort.allCases) { sort in
            Text(sort.title).tag(sort)
          }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("live.channel.sort")
      }

      if !viewModel.submittedQuery.isEmpty {
        HStack {
          Text("Results for “\(viewModel.submittedQuery)”")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
          Button("Back to all videos") {
            Task { await viewModel.clearChannelSearch() }
          }
          .font(.caption.weight(.semibold))
        }
      }
    }
  }

  private var isYouTube: Bool {
    LiveChannelRequestURLBuilder.isYouTube(viewModel.channelURL)
  }

  private var tabBinding: Binding<LiveChannelTab> {
    Binding(
      get: { viewModel.selectedTab },
      set: { tab in
        Task { await viewModel.selectTab(tab) }
      }
    )
  }

  private var sortBinding: Binding<LiveChannelSort> {
    Binding(
      get: { viewModel.sort },
      set: { sort in
        Task { await viewModel.selectSort(sort) }
      }
    )
  }
}
