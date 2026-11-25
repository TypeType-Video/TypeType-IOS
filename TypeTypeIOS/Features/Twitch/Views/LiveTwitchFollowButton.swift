import SwiftUI

@MainActor
final class LiveTwitchFollowModel: ObservableObject {
  @Published private(set) var linked: Bool?
  @Published private(set) var state: LiveTwitchFollowState?
  @Published private(set) var pending = false
  @Published private(set) var failed = false

  var subscription: LiveTwitchSubscription? { state?.subscription }

  func load(login: String, account: LiveTwitchAccountServiceProtocol) async {
    guard let status = try? await account.account() else { return }
    linked = status.linked
    guard status.linked else { return }
    state = try? await account.follow(login: login)
  }

  func toggle(login: String, account: LiveTwitchAccountServiceProtocol) async {
    guard let state else { return }
    pending = true
    defer { pending = false }
    do {
      self.state = try await account.setFollow(login: login, following: !state.following)
      failed = false
    } catch {
      failed = true
    }
  }
}

// One line, never wrapped: the row around it gives way, not the label.
struct LiveTwitchFollowButton: View {
  @ObservedObject var model: LiveTwitchFollowModel
  let login: String
  var onLink: (() -> Void)?
  @Environment(\.liveTwitchAccount) private var account

  var body: some View {
    if let account {
      Group {
        if model.linked == false, let onLink {
          Button(action: onLink) { Label("Follow", systemImage: "heart") }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .accessibilityHint(Text("Link a Twitch account to follow channels."))
        } else if model.linked == false {
          NavigationLink(value: LiveTwitchRoute.linkAccount) { Label("Follow", systemImage: "heart") }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .accessibilityHint(Text("Link a Twitch account to follow channels."))
        } else if let state = model.state {
          Button { Task { await model.toggle(login: login, account: account) } } label: {
            Label(state.following ? "Following" : "Follow", systemImage: state.following ? "heart.fill" : "heart")
          }
          .buttonStyle(.borderedProminent)
          .tint(state.following ? .secondary : .purple)
          .disabled(model.pending)
          .accessibilityLabel(state.following ? Text("Unfollow") : Text("Follow"))
          .accessibilityAddTraits(state.following ? .isSelected : [])
        }
      }
      .controlSize(.small)
      .lineLimit(1)
      .fixedSize()
      .accessibilityIdentifier("live.twitch.follow")
    }
  }
}

struct LiveTwitchFollowRow: View {
  let login: String
  @StateObject private var model = LiveTwitchFollowModel()
  @Environment(\.liveTwitchAccount) private var account

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        LiveTwitchFollowButton(model: model, login: login)
        if let subscription = model.subscription { LiveTwitchSubBadge(subscription: subscription) }
      }
      if model.failed {
        Text("Twitch refused the follow.").font(.caption).foregroundStyle(.red)
      }
    }
    .task(id: login) {
      if let account { await model.load(login: login, account: account) }
    }
  }
}

struct LiveTwitchSubBadge: View {
  let subscription: LiveTwitchSubscription

  var body: some View {
    Label { Text(verbatim: LiveTwitchChatText.subscription(subscription)) } icon: { Image(systemName: "star.fill") }
      .font(.caption.weight(.semibold))
      .foregroundStyle(.purple)
      .lineLimit(1)
      .fixedSize()
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(Color.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(verbatim: ([LiveTwitchChatText.subscription(subscription)] + LiveTwitchChatText.subscriptionDetails(subscription)).joined(separator: ", ")))
  }
}
