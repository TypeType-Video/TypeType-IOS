import SwiftUI

extension DemoSearchView {
  var results: some View {
    Group {
      if resultState == .normal {
        loadedResults
      } else {
        DemoSearchStateView(state: resultState) {
          resultState = .loading
          Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(550))
            resultState = .normal
          }
        }
      }
    }
  }

  var loadedResults: some View {
    VStack(alignment: .leading, spacing: 22) {
      DemoSearchScopeBar(selection: $selectedScope)
      DemoSearchAdvancedFilterBar(
        service: $selectedService,
        content: $contentFilter,
        sort: $sortOrder
      )

      if let suggestion = DemoSearchCatalog.suggestion(for: normalizedQuery) {
        Button {
          query = suggestion
          rememberQuery()
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text("Did you mean ")
            Text(suggestion).fontWeight(.semibold)
            Spacer()
            Image(systemName: "chevron.right")
          }
          .font(.footnote)
          .foregroundStyle(.primary)
          .padding(13)
          .background(Color(red: 1, green: 0.31, blue: 0.34).opacity(0.14))
          .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
          .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Did you mean \(suggestion)")
        .accessibilityIdentifier("demo.search.suggestion")
      }

      if totalResultCount == 0 {
        emptyResults
      } else {
        if showsChannels && !channels.isEmpty {
          channelResults
        }
        if showsPlaylists && !playlists.isEmpty {
          playlistResults
        }
        if showsVideos && !videos.isEmpty {
          videoResults
        }
      }
    }
  }

  var channelResults: some View {
    VStack(alignment: .leading, spacing: 12) {
      resultHeading("Channels", count: channels.count)
      LazyVStack(spacing: 10) {
        ForEach(channels) { channel in
          DemoSearchChannelRow(channel: channel) {
            selectedChannel = channel
          }
        }
      }
      .padding(.horizontal, 16)
    }
  }

  var playlistResults: some View {
    VStack(alignment: .leading, spacing: 12) {
      resultHeading("Playlists", count: playlists.count)
      LazyVStack(spacing: 10) {
        ForEach(playlists) { playlist in
          DemoSearchPlaylistRow(playlist: playlist) {
            selectedPlaylist = playlist
          }
        }
      }
      .padding(.horizontal, 16)
    }
  }

  var videoResults: some View {
    VStack(alignment: .leading, spacing: 14) {
      resultHeading("Videos", count: videos.count)
      LazyVStack(spacing: 24) {
        ForEach(visibleVideos) { video in
          DemoVideoCard(video: video) {
            selectedVideo = $0
          }
        }
        LiveIncrementalLoadingTrigger(
          canLoadMore: canLoadMoreVideos,
          isLoading: isLoadingMore,
          label: "Loading more videos",
          identifier: "demo.search.loading",
          action: loadMoreVideos
        )
      }
      .padding(.horizontal, 16)
    }
  }

  var emptyResults: some View {
    ContentUnavailableView {
      Label(
        session.isInstanceAllowListRestricted
          ? "Outside the family list"
          : "No results",
        systemImage: session.isInstanceAllowListRestricted
          ? "person.2.slash"
          : "magnifyingglass"
      )
    } description: {
      Text(
        session.isInstanceAllowListRestricted
          ? "Only channels and playlists approved by the instance administrator are visible."
          : "Try fewer words, another service, or a broader content filter."
      )
    } actions: {
      Button(session.isInstanceAllowListRestricted ? "Clear search" : "Search for SABR") {
        query = session.isInstanceAllowListRestricted ? "" : "SABR"
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 60)
  }

  func resultHeading(_ title: String, count: Int) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(.title3.weight(.semibold))
      Text("\(count)")
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
    }
    .padding(.horizontal, 16)
  }
}
