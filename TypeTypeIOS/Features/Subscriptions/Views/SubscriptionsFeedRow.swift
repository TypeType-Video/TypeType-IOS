import SwiftUI

struct SubscriptionsFeedRow: View {
  let video: HomeVideoItem

  var body: some View {
    HomeVideoRowView(video: video)
  }
}
