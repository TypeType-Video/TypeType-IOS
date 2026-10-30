import Foundation

struct LiveNotificationChannel: Identifiable, Equatable {
  let preference: LiveChannelNotificationPreference
  let subscription: LiveSubscription?

  var id: String { preference.channelURL }

  var name: String {
    if let name = subscription?.name, !name.isEmpty { return name }
    let last = URL(string: preference.channelURL)?.lastPathComponent ?? ""
    return last.isEmpty ? preference.channelURL : last
  }

  var avatarURL: URL? {
    subscription.flatMap { URL(string: $0.avatarURL) }
  }
}
