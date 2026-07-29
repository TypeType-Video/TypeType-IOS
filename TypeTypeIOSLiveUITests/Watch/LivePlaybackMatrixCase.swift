import Foundation

struct LivePlaybackMatrixCase {
  let provider: String
  let serviceID: Int
  let query: String
  let expectedID: String
  let duration: TimeInterval
  let holdSeconds: TimeInterval
  let chapterTitle: String?
  let seekTarget: TimeInterval?
  let sponsorSkipEnd: TimeInterval?
  let expectsLive: Bool

  init(
    provider: String = "YouTube",
    serviceID: Int = 0,
    query: String,
    expectedID: String,
    duration: TimeInterval,
    holdSeconds: TimeInterval = 30,
    chapterTitle: String? = nil,
    seekTarget: TimeInterval? = nil,
    sponsorSkipEnd: TimeInterval? = nil,
    expectsLive: Bool = false
  ) {
    self.provider = provider
    self.serviceID = serviceID
    self.query = query
    self.expectedID = expectedID
    self.duration = duration
    self.holdSeconds = holdSeconds
    self.chapterTitle = chapterTitle
    self.seekTarget = seekTarget
    self.sponsorSkipEnd = sponsorSkipEnd
    self.expectsLive = expectsLive
  }
}

extension LivePlaybackMatrixCase {
  static let current: [Self] = [
    Self(
      query: "_xjxwl1zLMc",
      expectedID: "_xjxwl1zLMc",
      duration: 768,
      holdSeconds: 300
    ),
    Self(
      query: "uZXjdwFGDdM",
      expectedID: "uZXjdwFGDdM",
      duration: 1_747,
      holdSeconds: 300
    ),
    Self(
      query: "iYlODtkyw_I",
      expectedID: "iYlODtkyw_I",
      duration: 2_104,
      holdSeconds: 300
    ),
    Self(
      query: "aqz-KE-bpKQ",
      expectedID: "aqz-KE-bpKQ",
      duration: 635
    ),
    Self(
      query: "zbqZ-0puJjg",
      expectedID: "zbqZ-0puJjg",
      duration: 707
    ),
    Self(
      query: "GK2pZ_oVU1o",
      expectedID: "GK2pZ_oVU1o",
      duration: 2_384,
      chapterTitle: "How To Read The Smith Chart",
      seekTarget: 1_553
    ),
    Self(
      query: "Qv5qQu0yMaU",
      expectedID: "Qv5qQu0yMaU",
      duration: 376,
      chapterTitle: "Solving Problems with Guns",
      seekTarget: 56,
      sponsorSkipEnd: 159.09
    ),
    Self(
      query: "KOpTWx1Eou4",
      expectedID: "KOpTWx1Eou4",
      duration: 273
    ),
    Self(
      query: "SdEPWRDl4ME",
      expectedID: "SdEPWRDl4ME",
      duration: 3_255
    ),
    Self(
      query: "2Q6OvYjOJi0",
      expectedID: "2Q6OvYjOJi0",
      duration: 1_166
    ),
    Self(
      query: "TfyPshgMbug",
      expectedID: "TfyPshgMbug",
      duration: 5_619,
      chapterTitle: "Why real-world tasks don’t fit into RL environments",
      seekTarget: 3_228
    ),
    Self(
      query: "WhWc3b3KhnY",
      expectedID: "WhWc3b3KhnY",
      duration: 464
    ),
    Self(
      query: "CtKyhp9m0K4",
      expectedID: "CtKyhp9m0K4",
      duration: 660
    ),
    Self(
      query: "awQzjn72bI0",
      expectedID: "awQzjn72bI0",
      duration: 0,
      holdSeconds: 60,
      expectsLive: true
    ),
    Self(
      provider: "BiliBili",
      serviceID: 5,
      query: "BV1xx411c7mD",
      expectedID: "BV1xx411c7mD",
      duration: 2_055,
      holdSeconds: 45
    ),
    Self(
      provider: "BiliBili",
      serviceID: 5,
      query: "BV1cN411d74Q",
      expectedID: "BV1cN411d74Q",
      duration: 1_193,
      holdSeconds: 45
    ),
    Self(
      provider: "BiliBili",
      serviceID: 5,
      query: "BV12V3v66E3B",
      expectedID: "BV12V3v66E3B",
      duration: 1_203,
      holdSeconds: 45
    ),
    Self(
      provider: "NicoNico",
      serviceID: 6,
      query: "邪神ちゃんのアテナ攻略3",
      expectedID: "sm46596608",
      duration: 1_024,
      holdSeconds: 45
    ),
    Self(
      provider: "NicoNico",
      serviceID: 6,
      query: "The Alley 後編",
      expectedID: "sm46596431",
      duration: 1_888,
      holdSeconds: 45
    ),
    Self(
      provider: "NicoNico",
      serviceID: 6,
      query: "Texas Chain Saw Massacre",
      expectedID: "sm46602641",
      duration: 718,
      holdSeconds: 45
    ),
  ]
}
