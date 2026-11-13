import SwiftUI

struct LiveChannelControlsView: View {
  @Environment(\.themePalette) private var palette
  @ObservedObject var viewModel: LiveChannelViewModel

  var body: some View {
    HStack(spacing: 10) {
      Menu {
        Picker("Channel section", selection: Binding(
          get: { viewModel.selectedTab },
          set: { tab in Task { await viewModel.selectTab(tab) } }
        )) {
          ForEach(tabs) { tab in
            Label(LocalizedStringKey(tab.title), systemImage: symbol(for: tab)).tag(tab)
          }
        }
        .pickerStyle(.inline)
      } label: {
        dropdownLabel(viewModel.selectedTab.title, systemImage: symbol(for: viewModel.selectedTab))
      }
      .accessibilityLabel(Text("Channel section"))
      .accessibilityValue(Text(LocalizedStringKey(viewModel.selectedTab.title)))
      .accessibilityIdentifier("live.channel.tabs")

      if viewModel.selectedTab == .videos, viewModel.submittedQuery.isEmpty {
        Menu {
          Picker("Video order", selection: Binding(
            get: { viewModel.sort },
            set: { sort in Task { await viewModel.selectSort(sort) } }
          )) {
            ForEach(LiveChannelSort.allCases) { sort in
              Text(LocalizedStringKey(sort.title)).tag(sort)
            }
          }
          .pickerStyle(.inline)
        } label: {
          dropdownLabel(viewModel.sort.title, systemImage: "arrow.up.arrow.down")
        }
        .accessibilityLabel(Text("Video order"))
        .accessibilityValue(Text(LocalizedStringKey(viewModel.sort.title)))
        .accessibilityIdentifier("live.channel.sort")
      }

      Spacer(minLength: 0)
    }
  }

  private var tabs: [LiveChannelTab] {
    LiveChannelTab.allCases.filter { tab in
      switch tab {
      case .about: true
      case .courses: isYouTube && viewModel.channel?.hasCourses == true
      default: isYouTube
      }
    }
  }

  private var isYouTube: Bool {
    LiveChannelRequestURLBuilder.isYouTube(viewModel.channelURL)
  }

  private func symbol(for tab: LiveChannelTab) -> String {
    switch tab {
    case .videos: "play.rectangle"
    case .live: "dot.radiowaves.left.and.right"
    case .playlists: "rectangle.stack"
    case .courses: "graduationcap"
    case .posts: "text.bubble"
    case .about: "info.circle"
    }
  }

  private func dropdownLabel(_ title: String, systemImage: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: systemImage)
      Text(LocalizedStringKey(title))
        .lineLimit(1)
      Image(systemName: "chevron.down")
        .font(.caption2.weight(.bold))
        .foregroundStyle(.secondary)
    }
    .font(.subheadline.weight(.semibold))
    .foregroundStyle(.primary)
    .padding(.horizontal, 12)
    .frame(height: 34)
    .background(palette.surface, in: Capsule())
  }
}
