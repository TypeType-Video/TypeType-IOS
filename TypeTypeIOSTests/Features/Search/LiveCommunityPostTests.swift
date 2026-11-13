import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveCommunityPostTests: XCTestCase {
  func testReadsPollsVideosAndSharedPosts() throws {
    let json = """
      {"posts":[{"id":"p1","text":"Vote!","authorName":"Blender","images":["https://yt3.ggpht.com/a.jpg"],
      "poll":{"choices":[{"text":"Yes"},{"text":"No","imageUrl":null}],"textualVoteCount":"1.2K votes"},
      "video":{"url":"https://www.youtube.com/watch?v=abc","title":"Spring"},
      "sharedPost":{"id":"p0","text":"Earlier","authorName":"Other"}}],"nextpage":"n2"}
      """
    let page = try JSONDecoder().decode(LiveCommunityPostsPage.self, from: Data(json.utf8))
    let post = try XCTUnwrap(page.posts.first)

    XCTAssertEqual(page.nextPage, "n2")
    XCTAssertEqual(post.poll?.choices, ["Yes", "No"])
    XCTAssertEqual(post.poll?.textualVoteCount, "1.2K votes")
    XCTAssertEqual(post.video?.title, "Spring")
    XCTAssertEqual(post.sharedPost?.post.text, "Earlier")
    XCTAssertEqual(post.images.count, 1)
  }

  func testPostsPageUntilTheLastCursor() async {
    let service = PostsChannelService()
    let model = LiveChannelPostsViewModel(channelURL: "https://www.youtube.com/@blender", service: service)

    await model.load()
    XCTAssertEqual(model.posts.map(\.id), ["a"])
    XCTAssertTrue(model.canLoadMore)
    await model.loadMore()

    XCTAssertEqual(model.posts.map(\.id), ["a", "b"])
    XCTAssertFalse(model.canLoadMore)
    XCTAssertEqual(service.cursors, ["-", "next"])
  }
}

private final class PostsChannelService: LiveChannelServiceProtocol {
  var cursors: [String] = []

  func channel(url: String, nextPage: String?, sort: LiveChannelSort) async throws -> LiveChannelPage { throw NetworkError.transport }
  func playlists(url: String, nextPage: String?, tab: String?) async throws -> LiveChannelPlaylistsPage { throw NetworkError.transport }
  func podcasts(url: String, nextPage: String?) async throws -> LivePodcastPage { throw NetworkError.transport }
  func podcastEpisodes(url: String, nextPage: String?) async throws -> LivePodcastEpisodesPage { throw NetworkError.transport }

  func posts(url: String, nextPage: String?) async throws -> LiveCommunityPostsPage {
    cursors.append(nextPage ?? "-")
    let json = nextPage == nil ? #"{"posts":[{"id":"a"}],"nextpage":"next"}"# : #"{"posts":[{"id":"a"},{"id":"b"}]}"#
    return try JSONDecoder().decode(LiveCommunityPostsPage.self, from: Data(json.utf8))
  }
}
