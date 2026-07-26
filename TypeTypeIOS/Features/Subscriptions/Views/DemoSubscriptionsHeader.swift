import SwiftUI

struct DemoSubscriptionsHeader: View {
  @EnvironmentObject private var session: DemoSessionStore
  @Binding var selection: DemoSubscriptionsView.Section

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 3) {
          Text("LIBRARY")
            .font(.caption2.weight(.semibold))
            .tracking(2)
            .foregroundStyle(.secondary)
          Text("\(session.followedChannelIDs.count) channels followed")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Button("Manage") {
          withAnimation(.snappy) {
            selection = .channels
          }
        }
          .font(.subheadline.weight(.semibold))
      }

      Picker("Subscription section", selection: $selection) {
        Text("Videos").tag(DemoSubscriptionsView.Section.videos)
        Text("Channels").tag(DemoSubscriptionsView.Section.channels)
      }
      .pickerStyle(.segmented)
      .accessibilityIdentifier("demo.subscriptions.picker")
    }
  }
}
