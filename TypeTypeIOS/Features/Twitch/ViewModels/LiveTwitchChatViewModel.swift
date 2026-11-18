import Foundation

@MainActor
final class LiveTwitchChatViewModel: ObservableObject {
  enum Status: Equatable {
    case connecting, live, reconnecting
  }

  static let highlightsRefresh: Duration = .seconds(10)

  @Published private(set) var chat = LiveTwitchChatState()
  @Published private(set) var status = Status.connecting
  @Published private(set) var emotes: [String: LiveTwitchThirdPartyEmote] = [:]
  @Published private(set) var badges: [String: LiveTwitchChatBadge] = [:]
  @Published private(set) var poll: LiveTwitchPoll?
  @Published private(set) var pinned: LiveTwitchPinnedMessage?
  @Published private(set) var account: LiveTwitchAccountStatus?
  @Published private(set) var isSending = false
  @Published var draft = ""
  @Published var notice: String?
  @Published private(set) var votedPollID: String?
  @Published private(set) var hiddenHighlights: Set<String> = []
  @Published private(set) var userEmotes: [LiveTwitchUserEmote] = []

  let login: String
  private let chatService: LiveTwitchChatService
  private let service: LiveTwitchAccountServiceProtocol
  private let signedIn: Bool

  init(login: String, chatService: LiveTwitchChatService, service: LiveTwitchAccountServiceProtocol, signedIn: Bool) {
    self.login = login
    self.chatService = chatService
    self.service = service
    self.signedIn = signedIn
  }

  var canWrite: Bool { account?.linked == true }
  var visiblePoll: LiveTwitchPoll? { poll.flatMap { hiddenHighlights.contains($0.id) ? nil : $0 } }
  var visiblePinned: LiveTwitchPinnedMessage? { pinned.flatMap { hiddenHighlights.contains($0.id) ? nil : $0 } }

  func run() async {
    async let stream: Void = follow()
    async let assets: Void = loadAssets()
    async let highlights: Void = refreshHighlights()
    async let linked: Void = loadAccount()
    _ = await (stream, assets, highlights, linked)
  }

  func loadUserEmotes() async {
    guard canWrite, userEmotes.isEmpty else { return }
    userEmotes = (try? await service.userEmotes(login: login).emotes) ?? []
  }

  func insert(_ name: String) {
    draft += (draft.isEmpty || draft.hasSuffix(" ") ? "" : " ") + name + " "
  }

  func hide(_ id: String) {
    hiddenHighlights.insert(id)
  }

  func send() async {
    let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard canWrite, !text.isEmpty, !isSending else { return }
    isSending = true
    defer { isSending = false }
    switch await service.send(text, login: login) {
    case .sent:
      draft = ""
      notice = nil
    case let .rejected(reason):
      notice = LiveTwitchChatRefusal(code: reason).message
    case .failed:
      notice = String(localized: "The message could not be sent.")
    }
  }

  func vote(_ choice: LiveTwitchPollChoice) async {
    guard canWrite, let poll else { return }
    switch await service.vote(pollID: poll.id, choiceID: choice.id) {
    case .counted:
      votedPollID = poll.id
      notice = nil
    case .freeVoteSpent:
      votedPollID = poll.id
      notice = String(localized: "You already voted in this poll.")
    case .failed:
      notice = String(localized: "Twitch did not count the vote.")
    }
  }

  private func follow() async {
    for await update in chatService.updates(login: login) {
      switch update {
      case .connected: status = .live
      case .reconnecting: status = .reconnecting
      case let .event(event): chat.apply(event)
      }
    }
  }

  private func loadAssets() async {
    (emotes, badges) = await LiveTwitchChatAssetsLoader.load(service, login: login)
  }

  private func refreshHighlights() async {
    while !Task.isCancelled {
      if let answer = try? await service.highlights(login: login) {
        if answer.poll?.id != poll?.id { votedPollID = nil }
        poll = answer.poll
        pinned = answer.pinned
      }
      do {
        try await Task.sleep(for: Self.highlightsRefresh)
      } catch {
        return
      }
    }
  }

  private func loadAccount() async {
    guard signedIn else { return }
    account = try? await service.account()
  }
}
