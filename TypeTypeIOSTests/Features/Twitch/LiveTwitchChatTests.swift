import XCTest
@testable import TypeTypeIOS

final class LiveTwitchChatStateTests: XCTestCase {
  func testKeepsTheLastMessagesAndMarksDeletionsAndClears() throws {
    var state = LiveTwitchChatState()
    for index in 0..<(LiveTwitchChatState.maximumMessages + 5) {
      state.apply(try event(#"{"type":"message","id":"m\#(index)","login":"user\#(index % 3)","text":"hi","time":"t"}"#))
    }
    state.apply(try event(#"{"type":"message","id":"m204","login":"user0","text":"again","time":"t"}"#))
    state.apply(try event(#"{"type":"delete","targetId":"m204","time":"t"}"#))
    state.apply(try event(#"{"type":"clear","login":"user1","time":"t"}"#))
    state.apply(try event(#"{"type":"room","time":"t","room":{"followersOnly":10,"slow":30,"emoteOnly":false,"subsOnly":true,"uniqueChat":false}}"#))

    XCTAssertEqual(state.messages.count, LiveTwitchChatState.maximumMessages)
    XCTAssertEqual(state.messages.first?.eventID, "m5")
    XCTAssertTrue(state.messages.first { $0.eventID == "m204" }?.deleted == true)
    XCTAssertTrue(state.messages.filter { $0.login == "user1" }.allSatisfy(\.deleted))
    XCTAssertFalse(state.messages.filter { $0.login == "user2" }.contains(where: \.deleted))
    XCTAssertEqual(state.room?.slow, 30)
    XCTAssertEqual(state.room?.subsOnly, true)
  }

  func testRefusalsSayWhyLikeTheWeb() {
    XCTAssertEqual(LiveTwitchChatRefusal(code: "msg_followersonly").reason, .followers)
    XCTAssertTrue(LiveTwitchChatRefusal(code: "msg_followersonly").suggestsFollowing)
    XCTAssertEqual(LiveTwitchChatRefusal(code: "msg_slowmode").reason, .slow)
    XCTAssertEqual(LiveTwitchChatRefusal(code: "msg_r9k").reason, .duplicate)
    XCTAssertEqual(LiveTwitchChatRefusal(code: "msg_banned").reason, .banned)
    XCTAssertEqual(LiveTwitchChatRefusal(code: nil).reason, .other(nil))
  }

  private func event(_ json: String) throws -> LiveTwitchChatEvent {
    try JSONDecoder().decode(LiveTwitchChatEvent.self, from: Data(json.utf8))
  }
}

final class LiveTwitchChatPartsTests: XCTestCase {
  func testSplitsTwitchEmotesByScalarAndThirdPartyEmotesByWord() throws {
    let thirdParty = [
      "KEKW": LiveTwitchThirdPartyEmote(name: "KEKW", url: "https://e.test/kekw", url2x: nil, provider: "bttv", animated: false, zeroWidth: false),
      "RainTime": LiveTwitchThirdPartyEmote(name: "RainTime", url: "https://e.test/rain", url2x: nil, provider: "7tv", animated: true, zeroWidth: true),
    ]
    let parts = LiveTwitchChatParts.parts(
      text: "é Kappa KEKW RainTime @Me look twitch.tv/blender_org!",
      native: [LiveTwitchChatEmote(id: "25", start: 2, end: 6)],
      emotes: thirdParty,
      selfLogin: "me"
    )

    guard parts.count >= 6 else { return XCTFail("Too few parts: \(parts)") }
    XCTAssertEqual(parts[0], .text("é "))
    if case let .emote(image, overlays) = parts[1] {
      XCTAssertEqual(image.name, "Kappa")
      XCTAssertEqual(image.url?.absoluteString, "https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/2.0")
      XCTAssertTrue(overlays.isEmpty)
    } else {
      XCTFail("Expected the Twitch emote")
    }
    if case let .emote(image, overlays) = parts[3] {
      XCTAssertEqual(image.name, "KEKW")
      XCTAssertEqual(overlays.map(\.name), ["RainTime"])
    } else {
      XCTFail("Expected the third-party emote with its overlay")
    }
    XCTAssertTrue(LiveTwitchChatParts.mentionsSelf(parts))
    XCTAssertTrue(parts.contains(.link("twitch.tv/blender_org", try XCTUnwrap(URL(string: "https://twitch.tv/blender_org")))))
  }

  func testNameColorsStayReadableLikeTheWeb() {
    let black = LiveTwitchChatText.nameRGB("#000000", login: "a", dark: true)
    XCTAssertEqual(black.0, 191)
    XCTAssertEqual(black.1, 191)
    let red = LiveTwitchChatText.nameRGB("#FF0000", login: "a", dark: true)
    XCTAssertEqual(red.0, 255)
    XCTAssertEqual(red.1, 0)
    let white = LiveTwitchChatText.nameRGB("FFFFFF", login: "a", dark: false)
    XCTAssertEqual(white.0, 102)
    let fallback = LiveTwitchChatText.nameRGB(nil, login: "a", dark: true)
    XCTAssertEqual(fallback.0, 46)
    XCTAssertEqual(fallback.2, 87)
  }

  func testOnlyKnownBareDomainsBecomeLinks() {
    XCTAssertNotNil(LiveTwitchChatParts.linkURL("example.com"))
    XCTAssertNil(LiveTwitchChatParts.linkURL("file.txt"))
    XCTAssertNotNil(LiveTwitchChatParts.linkURL("https://example.zz"))
  }
}

final class LiveTwitchVodChatWindowTests: XCTestCase {
  func testLoadsFromThePositionThenTheNextPageAndStartsOverAfterASeek() throws {
    var window = LiveTwitchVodChatWindow()
    XCTAssertEqual(window.request(at: 100), .offset(100))
    window.apply(try page((100...130).map(Double.init), cursor: "next"), for: .offset(100), at: 100)

    XCTAssertNil(window.request(at: 105))
    XCTAssertEqual(window.request(at: 115), .cursor("next"))
    window.apply(try page((131...160).map(Double.init), cursor: nil, more: false), for: .cursor("next"), at: 115)
    XCTAssertEqual(window.visibleComments(at: 120).last?.offset, 120)
    XCTAssertNil(window.request(at: 150))
    XCTAssertEqual(window.request(at: 400), .offset(400))
  }

  private func page(_ offsets: [Double], cursor: String?, more: Bool = true) throws -> LiveTwitchPage<LiveTwitchVideoComment> {
    let items = try offsets.map { offset in
      try JSONDecoder().decode(LiveTwitchVideoComment.self, from: Data(#"{"id":"c\#(offset)","offset":\#(offset),"text":"hi"}"#.utf8))
    }
    return LiveTwitchPage(items: items, cursor: cursor, hasMore: more)
  }
}

final class LiveTwitchChatServiceTests: XCTestCase {
  func testDecodesEventsAndReconnectsAfterADrop() async {
    let transport = ScriptedTransport(rounds: [
      "data: {\"type\":\"message\",\"id\":\"a\",\"text\":\"hi\",\"time\":\"t\"}\n\n",
      "data: {\"type\":\"room\",\"time\":\"t\",\"room\":{\"slow\":5}}\n\n",
    ])
    let service = LiveTwitchChatService(transport: transport) { _ in }
    var updates: [String] = []
    for await update in service.updates(login: "blender_org") {
      switch update {
      case .connected: updates.append("connected")
      case let .event(event): updates.append(event.kind.rawValue)
      case .reconnecting: updates.append("reconnecting")
      }
      if updates.count == 6 { break }
    }

    XCTAssertEqual(updates, ["connected", "message", "reconnecting", "connected", "room", "reconnecting"])
  }
}

private final class ScriptedTransport: LiveTwitchChatTransport, @unchecked Sendable {
  private let lock = NSLock()
  private var rounds: [String]

  init(rounds: [String]) {
    self.rounds = rounds
  }

  func openTwitchChat(login: String) async throws -> AsyncThrowingStream<UInt8, Error> {
    let text = lock.withLock { rounds.isEmpty ? "" : rounds.removeFirst() }
    return AsyncThrowingStream { continuation in
      for byte in Array(text.utf8) { continuation.yield(byte) }
      continuation.finish()
    }
  }
}
