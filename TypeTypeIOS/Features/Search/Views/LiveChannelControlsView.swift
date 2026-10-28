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

  /// Content tabs need the YouTube listing endpoints; About is local
  /// channel data and always available.
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

  /// Glass popover with checkmark rows and hairline dividers — the
  /// LiveOptionMenu recipe. `presentationCompactAdaptation(.popover)` is
  /// what keeps it a bubble on iPhone instead of a full-height sheet. The
  /// rows scroll inside a height cap so the bubble always appears fully
  /// (the subscriptions-page rule: never clipped).
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
              Spacer(minLength: 12)
              if option.selected {
                Image(systemName: "checkmark")
                  .foregroundStyle(DemoTheme.accent)
              }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          if index < options.count - 1 {
            Rectangle()
              .fill(DemoTheme.separator)
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
      DemoTheme.surface,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(DemoTheme.separator.opacity(0.55), lineWidth: 0.5)
    }
  }
}
