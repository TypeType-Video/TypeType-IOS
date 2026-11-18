import SwiftUI

struct LiveTwitchFollowButton: View {
  let login: String
  @Environment(\.liveTwitchAccount) private var account
  @State private var linked: Bool?
  @State private var state: LiveTwitchFollowState?
  @State private var pending = false
  @State private var failed = false

  var body: some View {
    if let account {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          if linked == false {
            NavigationLink(value: LiveTwitchRoute.linkAccount) {
              Label("Follow", systemImage: "heart")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(Text("Link a Twitch account to follow channels."))
          } else if let state {
            Button { Task { await toggle(account, following: !state.following) } } label: {
              Label(state.following ? "Following" : "Follow", systemImage: state.following ? "heart.fill" : "heart")
            }
            .buttonStyle(.borderedProminent)
            .tint(state.following ? .secondary : .purple)
            .disabled(pending)
            .accessibilityLabel(state.following ? Text("Unfollow") : Text("Follow"))
            .accessibilityAddTraits(state.following ? .isSelected : [])
            if let subscription = state.subscription { LiveTwitchSubBadge(subscription: subscription) }
          }
        }
        .controlSize(.small)
        if failed {
          Text("Twitch refused the follow.").font(.caption).foregroundStyle(.red)
        }
      }
      .task(id: login) { await load(account) }
    }
  }

  private func load(_ account: LiveTwitchAccountServiceProtocol) async {
    guard let status = try? await account.account() else { return }
    linked = status.linked
    guard status.linked else { return }
    state = try? await account.follow(login: login)
  }

  private func toggle(_ account: LiveTwitchAccountServiceProtocol, following: Bool) async {
    pending = true
    defer { pending = false }
    do {
      state = try await account.setFollow(login: login, following: following)
      failed = false
    } catch {
      failed = true
    }
  }
}

struct LiveTwitchSubBadge: View {
  let subscription: LiveTwitchSubscription

  var body: some View {
    Label { Text(verbatim: LiveTwitchChatText.subscription(subscription)) } icon: { Image(systemName: "star.fill") }
      .font(.caption.weight(.semibold))
      .foregroundStyle(.purple)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(Color.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(verbatim: ([LiveTwitchChatText.subscription(subscription)] + LiveTwitchChatText.subscriptionDetails(subscription)).joined(separator: ", ")))
  }
}
