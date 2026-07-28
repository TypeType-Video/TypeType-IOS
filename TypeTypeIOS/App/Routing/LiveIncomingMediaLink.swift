import Foundation

struct LiveIncomingMediaLink: Identifiable {
  let id = UUID()
  let destination: LiveMediaLinkDestination
}
