import Foundation
import SwiftUI

struct LiveChannelControlsView: View {
  @Environment(\.themePalette) private var palette
  @ObservedObject var viewModel: LiveChannelViewModel
  @State private var presentsSections = false
  @State private var presentsSort = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        Button {
          presentsSections = true
        } label: {
          dropdownLabel(
            viewModel.selectedTab.title,
            systemImage: sectionSymbol
          )
        }
        .buttonStyle(.plain)
        .popover(
          isPresented: $presentsSections,
          attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
          arrowEdge: .top
        ) {
          optionList(
            tabs.map {
              (id: $0.id, label: $0.title, selected: viewModel.selectedTab == $0)
            }
          ) { id in
            guard let tab = tabs.first(where: { $0.id == id }) else {
              return
            }
            presentsSections = false
            Task { await viewModel.selectTab(tab) }
          }
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
          .popover(
            isPresented: $presentsSort,
            attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
            arrowEdge: .top
          ) {
            optionList(
              LiveChannelSort.allCases.map {
                (id: $0.id, label: $0.title, selected: viewModel.sort == $0)
              }
            ) { id in
              guard let sort = LiveChannelSort.allCases.first(where: {
                $0.id == id
              }) else {
                return
              }
              presentsSort = false
              Task { await viewModel.selectSort(sort) }
            }
          }
          .accessibilityLabel("Video order")
          .accessibilityValue(viewModel.sort.title)
          .accessibilityIdentifier("live.channel.sort")
        }

        Spacer(minLength: 0)
      }
    }
  }

  private var tabs: [LiveChannelTab] {
    LiveChannelTab.allCases.filter { isYouTube || $0 == .about }
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

  private func optionList(
    _ options: [(id: String, label: String, selected: Bool)],
    onSelect: @escaping (String) -> Void
  ) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
          Button {
            onSelect(option.id)
          } label: {
            HStack(spacing: 12) {
              Text(option.label)
                .foregroundStyle(.primary)
                .lineLimit(2)
              Spacer(minLength: 12)
              if option.selected {
                Image(systemName: "checkmark")
                  .foregroundStyle(palette.accent)
              }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          if index < options.count - 1 {
            Rectangle()
              .fill(palette.separator)
              .frame(height: 1)
              .padding(.horizontal, 16)
          }
        }
      }
      .frame(width: 280)
    }
    .frame(maxHeight: 440)
    .presentationCompactAdaptation(.popover)
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
      palette.surface,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(palette.separator.opacity(0.55), lineWidth: 0.5)
    }
  }
}
