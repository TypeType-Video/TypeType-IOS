import Foundation
import SwiftUI

struct LiveChannelControlsView: View {
  @ObservedObject var viewModel: LiveChannelViewModel
  @State private var presentsSections = false
  @State private var presentsSort = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        // Popovers, not system menus: the iOS 26/27 glass menu popup
        // crashes on item taps with `setEffect:` in this app.
        Button {
          presentsSections = true
        } label: {
          dropdownLabel(
            viewModel.selectedTab.title,
            systemImage: sectionSymbol
          )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $presentsSections) {
          VStack(alignment: .leading, spacing: 2) {
            ForEach(LiveChannelTab.allCases) { tab in
              // Content tabs need the YouTube listing endpoints; About is
              // local channel data and always available.
              if isYouTube || tab == .about {
                Button {
                  presentsSections = false
                  Task { await viewModel.selectTab(tab) }
                } label: {
                  menuLabel(
                    tab.title,
                    selected: viewModel.selectedTab == tab
                  )
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(12)
        }
        .accessibilityLabel("Channel section")
        .accessibilityValue(viewModel.selectedTab.title)
        .accessibilityIdentifier("live.channel.tabs")

        if viewModel.selectedTab == .videos,
          viewModel.submittedQuery.isEmpty {
          Button {
            presentsSort = true
          } label: {
            dropdownLabel(
              viewModel.sort.title,
              systemImage: "arrow.up.arrow.down"
            )
          }
          .buttonStyle(.plain)
          .popover(isPresented: $presentsSort) {
            VStack(alignment: .leading, spacing: 2) {
              ForEach(LiveChannelSort.allCases) { sort in
                Button {
                  presentsSort = false
                  Task { await viewModel.selectSort(sort) }
                } label: {
                  menuLabel(sort.title, selected: viewModel.sort == sort)
                }
                .buttonStyle(.plain)
              }
            }
            .padding(12)
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
