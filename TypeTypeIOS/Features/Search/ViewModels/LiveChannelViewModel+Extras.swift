import Foundation

extension LiveChannelViewModel {
  func loadPlaylists() async {
    requestID = UUID()
    state = .loading
    canLoadMore = false
    nextPage = nil
    do {
      let page = try await channelService.playlists(
        url: channelURL,
        nextPage: nil,
        tab: playlistTab
      )
      playlists = Self.uniquePlaylists(page.playlists)
      nextPage = page.nextPage
      canLoadMore = page.nextPage?.isEmpty == false
      state = playlists.isEmpty ? .empty : .loaded
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  func loadMorePlaylists() async {
    guard canLoadMore, !isLoadingMore else { return }
    guard let nextPage, !nextPage.isEmpty else { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await channelService.playlists(
        url: channelURL,
        nextPage: nextPage,
        tab: playlistTab
      )
      playlists = Self.uniquePlaylists(playlists + page.playlists)
      self.nextPage = page.nextPage
      canLoadMore = page.nextPage?.isEmpty == false
    } catch {
      canLoadMore = true
    }
  }

  private var playlistTab: String? {
    selectedTab == .courses ? "courses" : nil
  }

  func loadPodcasts() async {
    guard LiveChannelRequestURLBuilder.isYouTube(channelURL) else {
      podcasts = []
      return
    }
    isLoadingPodcasts = true
    defer { isLoadingPodcasts = false }
    do {
      let page = try await channelService.podcasts(
        url: channelURL,
        nextPage: nil
      )
      podcasts = Self.uniquePodcasts(page.podcasts)
      podcastNextPage = page.nextPage
      canLoadMorePodcasts = page.nextPage?.isEmpty == false
    } catch {
      podcasts = []
      canLoadMorePodcasts = false
    }
  }

  func loadMorePodcasts() async {
    guard canLoadMorePodcasts, !isLoadingPodcasts else { return }
    guard let podcastNextPage, !podcastNextPage.isEmpty else {
      return
    }
    isLoadingPodcasts = true
    defer { isLoadingPodcasts = false }
    do {
      let page = try await channelService.podcasts(
        url: channelURL,
        nextPage: podcastNextPage
      )
      podcasts = Self.uniquePodcasts(podcasts + page.podcasts)
      self.podcastNextPage = page.nextPage
      canLoadMorePodcasts = page.nextPage?.isEmpty == false
    } catch {
      canLoadMorePodcasts = true
    }
  }

  func refreshSubscriptionStatus() async {
    do {
      let values = try await subscriptionsService.subscriptions()
      isSubscribed = values.contains {
        Self.normalizedURL($0.channelURL)
          == Self.normalizedURL(channelURL)
      }
    } catch {
      isSubscribed = false
    }
  }

  func refreshNotificationPreference() async {
    guard isSubscribed,
      let service = pushNotificationsService,
      pushNotificationsEnabled
    else {
      isNotificationsAvailable = false
      isNotificationsEnabled = false
      return
    }

    do {
      let preferences = try await service.channelPreferences()
      isNotificationsEnabled = preferences.first {
        $0.matches(channelURL: channelURL)
      }?.enabled == true
      isNotificationsAvailable = true
    } catch {
      isNotificationsAvailable = false
      isNotificationsEnabled = false
    }
  }

  func toggleNotifications() async {
    guard isNotificationsAvailable,
      !isChangingNotifications,
      let service = pushNotificationsService
    else {
      return
    }

    isChangingNotifications = true
    subscriptionError = nil
    let newValue = !isNotificationsEnabled
    do {
      _ = try await service.setChannelPreference(
        channelURL: channelURL,
        enabled: newValue
      )
      isNotificationsEnabled = newValue
    } catch {
      subscriptionError = (error as? LocalizedError)?
        .errorDescription ?? "Channel notifications could not be updated."
    }
    isChangingNotifications = false
  }

  func toggleSubscription() async {
    guard let channel, !isChangingSubscription else { return }
    isChangingSubscription = true
    subscriptionError = nil
    defer { isChangingSubscription = false }
    do {
      if isSubscribed {
        try await subscriptionsService.unsubscribe(
          channelURL: channelURL
        )
        isSubscribed = false
        isNotificationsAvailable = false
        isNotificationsEnabled = false
      } else {
        _ = try await subscriptionsService.subscribe(
          channelURL: channelURL,
          name: channel.name,
          avatarURL: channel.avatarURL
        )
        isSubscribed = true
        await refreshNotificationPreference()
      }
    } catch {
      subscriptionError = (error as? LocalizedError)?
        .errorDescription ?? "Subscription could not be updated."
    }
  }

  private static func uniquePlaylists(
    _ candidates: [LivePlaylistResult]
  ) -> [LivePlaylistResult] {
    var seen: Set<String> = []
    return candidates.filter {
      seen.insert($0.canonicalID).inserted
    }
  }

  private static func uniquePodcasts(
    _ candidates: [LivePodcastItem]
  ) -> [LivePodcastItem] {
    var seen: Set<String> = []
    return candidates.filter { seen.insert($0.url).inserted }
  }

  private static func normalizedURL(_ value: String) -> String {
    LiveChannelURLCanonicalizer.identity(value)
  }
}
