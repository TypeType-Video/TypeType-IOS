import Foundation

enum LiveAlgorithmLabels {
  static func data(_ id: String) -> String {
    switch id {
    case "history": String(localized: "Video history")
    case "shorts_history": String(localized: "Shorts history")
    case "events": String(localized: "Interactions")
    case "search": String(localized: "Search history")
    case "favorites": String(localized: "Favorites")
    case "watch_later": String(localized: "Watch later")
    case "subscriptions": String(localized: "Subscriptions")
    case "blocked": String(localized: "Blocked content")
    case "not_interested": String(localized: "Not interested")
    case "shown": String(localized: "Shown on the home page")
    default: id
    }
  }

  static func dropped(_ why: String, count: Int) -> String {
    switch why {
    case "seen": String(localized: "\(count) already watched")
    case "blocked": String(localized: "\(count) blocked")
    case "channel_cap": String(localized: "\(count) too many from one channel")
    case "muted": String(localized: "\(count) hidden interests")
    case "excluded": String(localized: "\(count) from excluded data")
    case "not_interested": String(localized: "\(count) not for you")
    case "short": String(localized: "\(count) Shorts")
    case "obscure": String(localized: "\(count) almost nobody watched")
    default: "\(count) \(why)"
    }
  }

  static func group(_ id: String) -> (title: String, help: String) {
    switch id {
    case "sources": (String(localized: "Sources"), String(localized: "Where the algorithm looks for candidate videos."))
    case "weights": (String(localized: "Weights"), String(localized: "What matters most when ranking the candidates."))
    case "decay": (String(localized: "Recent videos"), String(localized: "How long a watched video keeps steering the home page."))
    case "rows": (String(localized: "Page"), String(localized: "The size of the page and how it is shared out."))
    case "exploration": (String(localized: "Discovery"), String(localized: "The room left for what you do not watch yet."))
    case "randomness": (String(localized: "Randomness"), String(localized: "Whether the home page changes on every refresh."))
    default: (id, "")
    }
  }

  static func retention(_ days: Int?) -> String {
    guard let days else { return String(localized: "No limit") }
    if days == 365 { return String(localized: "1 year") }
    if days >= 180 { return String(localized: "\(Int((Double(days) / 30).rounded())) months") }
    return String(localized: "\(days) d")
  }

  static func sources(_ trace: LiveRecommenderTrace) -> String {
    let count = { (kind: String) in trace.sources.filter { $0.kind == kind }.count }
    return [
      count("subscription_feed") > 0 ? String(localized: "subscriptions feed") : nil,
      count("related") > 0 ? String(localized: "videos related to \(count("related")) watched videos") : nil,
      count("channel_videos") > 0 ? String(localized: "catalogue of \(count("channel_videos")) channels") : nil,
      count("search") > 0 ? String(localized: "\(count("search")) searches") : nil,
      count("trending") > 0 ? String(localized: "trending") : nil,
    ].compactMap { $0 }.joined(separator: ", ")
  }

  static func opinion(_ opinion: LiveRecommenderOpinion) -> String {
    if opinion.kind == "video" { return String(localized: "Not for me") }
    return opinion.verdict == "good" ? String(localized: "Good") : String(localized: "Not good")
  }

  static func reason(_ reason: String?) -> String? {
    switch reason {
    case "seen": String(localized: "Already seen")
    case "channel": String(localized: "Not this channel")
    case "topic": String(localized: "Not this topic")
    case "other": String(localized: "Other")
    case "repetitive": String(localized: "Too repetitive")
    case "unrelated": String(localized: "Nothing to do with me")
    case "old": String(localized: "Too many old videos")
    case "missing": String(localized: "My channels are missing")
    default: nil
    }
  }
}
