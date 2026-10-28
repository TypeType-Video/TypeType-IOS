import Foundation
import SwiftUI

struct LiveChannelControlsView: View {
  @ObservedObject var viewModel: LiveChannelViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        Menu {
          ForEach(LiveChannelTab.allCases) { tab in
            // Content tabs need the YouTube listing endpoints; About is
            // local channel data and always available.
            if isYouTube || tab == .about {
              Button {
                Task { await viewModel.selectTab(tab) }
              } label: {
                menuLabel(
                  tab.title,
                  selected: viewModel.selectedTab == tab
                )
              }
            }
          }
        } label: {
          dropdownLabel(
            viewModel.selectedTab.title,
            systemImage: sectionSymbol
          )
        }
        .accessibilityLabel("Channel section")
        .accessibilityValue(viewModel.selectedTab.title)
        .accessibilityIdentifier("live.channel.tabs")

        if viewModel.selectedTab == .videos,
          viewModel.submittedQuery.isEmpty {
          Menu {
            ForEach(LiveChannelSort.allCases) { sort in
              Button {
                Task { await viewModel.selectSort(sort) }
              } label: {
                menuLabel(
                  sort.title,
                  selected: viewModel.sort == sort
                )
              }
            }
          } label: {
            dropdownLabel(
              viewModel.sort.title,
              systemImage: "arrow.up.arrow.down"
            )
          }
          .accessibilityLabel("Video order")
          .accessibilityValue(viewModel.sort.title)
          .accessibilityIdentifier("live.channel.sort")
        }

        Spacer(minLength: 0)
      }
    }
  }

  private var isYouTube: Bool {
    LiveChannelRequestURLBuilder.isYouTube(viewModel.channelURL)
  }

  private var sectionSymbol: String {
    switch viewModel.selectedTab {
    case .videos: return "play.rectangle"
    case .live: return "dot.radiowaves.left.and.right"
    case .playlists: return "rectangle.stack"
    case .about: return "info.circle"
    }
  }

  private func dropdownLabel(
    _ title: String,
    systemImage: String
  ) -> some View {
    HStack(spacing: 7) {
      Image(systemName: systemImage)
      Text(title)
        .lineLimit(1)
      Image(systemName: "chevron.down")
        .font(.caption2.weight(.bold))
        .foregroundStyle(.secondary)
    }
    .font(.subheadline.weight(.semibold))
    .foregroundStyle(.primary)
    .padding(.horizontal, 12)
    .padding(.vertical, 9)
    .background(
      DemoTheme.surface,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(DemoTheme.separator.opacity(0.55), lineWidth: 0.5)
    }
  }

  @ViewBuilder
  private func menuLabel(
    _ title: String,
    selected: Bool
  ) -> some View {
    if selected {
      Label(title, systemImage: "checkmark")
    } else {
      Text(title)
    }
  }
}
