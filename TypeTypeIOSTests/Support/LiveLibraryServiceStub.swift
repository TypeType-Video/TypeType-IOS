import Foundation
@testable import TypeTypeIOS

final class LiveLibraryServiceStub: LiveLibraryServiceProtocol {
  var favoriteItems: [LiveFavoriteItem] = []
  var watchLaterItems: [LiveWatchLaterItem] = []
  private(set) var actions: [String] = []

  func favorites() async throws -> [LiveFavoriteItem] {
    favoriteItems
  }

  func favorite(videoURL: String) async throws -> LiveFavoriteItem? {
    favoriteItems.first { $0.videoURL == videoURL }
  }

  func addFavorite(videoURL: String) async throws -> LiveFavoriteItem {
    let item = LiveLibraryFixtures.favorite(url: videoURL)
    favoriteItems.append(item)
    actions.append("favorite:\(videoURL)")
    return item
  }

  func removeFavorite(videoURL: String) async throws {
    favoriteItems.removeAll { $0.videoURL == videoURL }
    actions.append("unfavorite:\(videoURL)")
  }

  func watchLater() async throws -> [LiveWatchLaterItem] {
    watchLaterItems
  }

  func addWatchLater(
    video: LiveVideoItem
  ) async throws -> LiveWatchLaterItem {
    let item = LiveLibraryFixtures.watchLater(url: video.url)
    watchLaterItems.append(item)
    actions.append("later:\(video.url)")
    return item
  }

  func removeWatchLater(videoURL: String) async throws {
    watchLaterItems.removeAll { $0.url == videoURL }
    actions.append("unlater:\(videoURL)")
  }
}
