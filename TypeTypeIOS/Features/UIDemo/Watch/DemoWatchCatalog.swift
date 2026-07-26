import Foundation

struct DemoWatchChapter: Identifiable {
  let id: String
  let title: String
  let timestamp: String
  let seconds: Double
}
struct DemoWatchReply: Identifiable {
  let id: String
  let author: String
  let message: String
  let detail: String
}
struct DemoWatchComment: Identifiable {
  let id: String
  let author: String
  let message: String
  let detail: String
  let likeCount: String
  let isPinned: Bool
  let isVerified: Bool
  let replies: [DemoWatchReply]
}
enum DemoWatchCatalog {
  static let chapters = [
    DemoWatchChapter(
      id: "opening",
      title: "A peaceful morning",
      timestamp: "0:00",
      seconds: 0
    ),
    DemoWatchChapter(
      id: "butterfly",
      title: "The butterfly arrives",
      timestamp: "1:44",
      seconds: 104
    ),
    DemoWatchChapter(
      id: "trouble",
      title: "Frank, Rinky, and Gamera",
      timestamp: "4:05",
      seconds: 245
    ),
    DemoWatchChapter(
      id: "payback",
      title: "Bunny's plan",
      timestamp: "6:21",
      seconds: 381
    ),
    DemoWatchChapter(
      id: "credits",
      title: "Open movie credits",
      timestamp: "9:13",
      seconds: 553
    ),
  ]

  static let comments = [
    DemoWatchComment(
      id: "openmedia",
      author: "@openmedia",
      message:
        "A perfect test film for an open-source video client. "
        + "The colors make quality changes immediately visible, and 1:44 is still my favorite shot. "
        + "Original: https://www.youtube.com/watch?v=YE7VzlLtp-4",
      detail: "4 years ago",
      likeCount: "128",
      isPinned: true,
      isVerified: true,
      replies: [
        DemoWatchReply(
          id: "openmedia-reply-1",
          author: "@typetype",
          message:
            "That is exactly why it became our reference video. Compare 4:05 with "
            + "https://www.nicovideo.jp/watch/sm9",
          detail: "42 likes"
        ),
        DemoWatchReply(
          id: "openmedia-reply-2",
          author: "@blender",
          message: "Open movies helping open clients — we love to see it.",
          detail: "31 likes"
        ),
      ]
    ),
    DemoWatchComment(
      id: "typetype",
      author: "@typetype",
      message:
        "This screen runs entirely on local mock data. The production path will use "
        + "TypeType's SABR playback stack while keeping the same calm iOS experience. "
        + "BiliBili links stay internal too: https://www.bilibili.com/video/BV1xx411c7mD",
      detail: "2 hours ago",
      likeCount: "94",
      isPinned: false,
      isVerified: true,
      replies: [
        DemoWatchReply(
          id: "typetype-reply-1",
          author: "@pipepipe",
          message: "Looking forward to testing seek recovery and codec switching.",
          detail: "18 likes"
        )
      ]
    ),
    DemoWatchComment(
      id: "selfhosted",
      author: "@selfhosted",
      message:
        "The audio-only action is a surprisingly useful touch. "
        + "I would also love a one-tap download preset for train journeys. "
        + "Production notes: https://studio.blender.org/films/big-buck-bunny/",
      detail: "yesterday",
      likeCount: "57",
      isPinned: false,
      isVerified: false,
      replies: []
    ),
    DemoWatchComment(
      id: "subtitles",
      author: "@captionnerd",
      message:
        "Please keep subtitle language, style, and forced-caption choices separate. "
        + "Most clients flatten them into one confusing switch.",
      detail: "3 days ago",
      likeCount: "39",
      isPinned: false,
      isVerified: false,
      replies: []
    ),
    DemoWatchComment(
      id: "sponsorblock",
      author: "@communitytools",
      message:
        "SponsorBlock chapters plus native scrubbing previews would make this a daily driver.",
      detail: "1 week ago",
      likeCount: "22",
      isPinned: false,
      isVerified: false,
      replies: []
    ),
    DemoWatchComment(
      id: "privacy",
      author: "@localfirst",
      message: "A video client that remembers my queue without profiling me is the right direction.",
      detail: "2 weeks ago",
      likeCount: "16",
      isPinned: false,
      isVerified: false,
      replies: []
    ),
  ]

  static let relatedVideos =
    DemoMockCatalog.recommendations
    + Array(DemoMockCatalog.continueWatching.dropFirst())

  static let queue = [
    DemoMockCatalog.continueWatching[0],
    DemoMockCatalog.recommendations[0],
    DemoMockCatalog.recommendations[1],
    DemoMockCatalog.recommendations[2],
  ]
}
