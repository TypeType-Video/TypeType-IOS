import SwiftUI

extension DemoSearchChannelDetailView {
  @ViewBuilder
  var channelContent: some View {
    switch effectiveChannelState {
    case "Loading":
      VStack(spacing: 12) {
        ProgressView()
        Text("Loading channel…")
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 80)
    case "Outside family list":
      ContentUnavailableView {
        Label("Outside the family list", systemImage: "person.crop.circle.badge.xmark")
      } description: {
        Text("A parent can add this channel to the trusted family space.")
      } actions: {
        Button("Add channel") {
          if !session.globalAllowedChannels.contains(channel.name) {
            session.globalAllowedChannels.append(channel.name)
          }
          channelState = "Normal"
        }
        .buttonStyle(.borderedProminent)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 80)
    case "Error":
      ContentUnavailableView {
        Label("Unable to load channel", systemImage: "wifi.exclamationmark")
      } actions: {
        Button("Retry") {
          channelState = "Normal"
        }
        .buttonStyle(.borderedProminent)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 80)
    default:
      normalContent
    }
  }
  var normalContent: some View {
    Group {
      DemoChannelDetailHeader(channel: channel)
      if selectedSection == "Videos" {
        DemoChannelPodcastsStrip(channel: channel)
      }
      Picker("Channel section", selection: $selectedSection) {
        Text("Videos").tag("Videos")
        Text("Live").tag("Live")
        Text("Playlists").tag("Playlists")
      }
      .pickerStyle(.segmented)
      .accessibilityIdentifier("demo.channel.section-picker")
      if selectedSection == "Videos" {
        filterBar
      }
      sectionContent
    }
  }
  private var filterBar: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 9) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(searchSecondaryText)
        TextField(
          "Search this channel",
          text: $query,
          prompt: Text("Search this channel")
            .foregroundStyle(searchSecondaryText)
        )
        .textFieldStyle(.plain)
        .foregroundStyle(.primary)
        .tint(session.preferences.accentColor)
        .submitLabel(.search)
        if !query.isEmpty {
          Button {
            query = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .accessibilityLabel("Clear channel search")
        }
      }
      .padding(.horizontal, 12)
      .frame(minHeight: 44)
      .background(secondarySurface)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      if query.isEmpty {
        Menu {
          ForEach(["Newest", "Popular", "Oldest"], id: \.self) { order in
            Button {
              sortOrder = order
            } label: {
              if sortOrder == order {
                Label(order, systemImage: "checkmark")
              } else {
                Text(order)
              }
            }
          }
        } label: {
          Label(sortOrder, systemImage: "arrow.up.arrow.down")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(secondarySurface)
            .clipShape(Capsule())
        }
      } else {
        HStack {
          Label("Searching this channel", systemImage: "text.magnifyingglass")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
          Button("Back to all videos") {
            query = ""
          }
          .font(.caption.weight(.semibold))
        }
      }
    }
  }
  @ViewBuilder
  private var sectionContent: some View {
    if selectedSection == "Playlists" {
      LazyVStack(spacing: 12) {
        ForEach(DemoChannelCatalog.playlists(for: channel)) { playlist in
          DemoSearchPlaylistRow(
            playlist: playlist
          ) {
            selectedPlaylist = playlist
          }
        }
      }
    } else if selectedSection == "Videos" {
      DemoChannelVideosSection(
        videos: filteredVideos,
        query: query,
        sortOrder: sortOrder,
        canLoadMore: canLoadMoreVideos,
        onSelect: { selectedVideo = $0 },
        onLoadMore: { visibleVideoCount += 4 }
      )
    } else {
      ContentUnavailableView(
        "No live streams",
        systemImage: "dot.radiowaves.left.and.right",
        description: Text("This mock channel is currently offline.")
      ).liveThemedEmptyState()
      .frame(maxWidth: .infinity)
      .padding(.top, 40)
    }
  }
  private var effectiveChannelState: String {
    if session.isInstanceAllowListRestricted
      && !session.globalAllowedChannels.contains(channel.name) {
      return "Outside family list"
    }
    return channelState
  }
}
