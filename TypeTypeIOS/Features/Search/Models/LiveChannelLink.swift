import Foundation

// Its own type, not String: every page opens a channel through a String destination, and a second String
// destination nested in the pushed channel page freezes the navigation stack.
struct LiveChannelLink: Hashable {
  let url: String
}
