import SwiftUI

extension DemoHomeFeedView {
  @ToolbarContentBuilder
  var leadingToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      HStack(spacing: 9) {
        Image("TypeTypeLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 25, height: 25)
          .offset(y: 1)
          .frame(width: 32, height: 32, alignment: .center)
        Text("TypeType")
          .font(.headline.weight(.bold))
      }
      .fixedSize(horizontal: true, vertical: false)
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("demo.home.brand")
    }
  }

  @ToolbarContentBuilder
  var trailingToolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarTrailing) {
      if let activeVideo = session.activeVideo {
        Button {
          selectedVideo = activeVideo
        } label: {
          Image(systemName: "play.rectangle.fill")
        }
        .accessibilityLabel("Open player")
        .accessibilityIdentifier("demo.home.player")
      }
      Button {
        presentsSearch = true
      } label: {
        Image(systemName: "magnifyingglass")
      }
      .accessibilityLabel("Search")
      .accessibilityIdentifier("demo.home.search")
      Button {
        presentsNotifications = true
      } label: {
        ZStack(alignment: .topTrailing) {
          Image(systemName: "bell")
          if unreadNotificationCount > 0 {
            Text(unreadNotificationCount > 99 ? "99+" : "\(unreadNotificationCount)")
              .font(.system(size: 7, weight: .bold))
              .foregroundStyle(.white)
              .padding(2)
              .background(.red, in: Capsule())
              .offset(x: 7, y: -6)
          }
        }
      }
      .accessibilityLabel("Notifications")
      .accessibilityIdentifier("demo.home.notifications")
      Menu {
        Button {
          presentsProfile = true
        } label: {
          Label("Profile", systemImage: "person.crop.circle")
        }
        Button("Toggle theme", systemImage: "moon.stars") {
          let next = session.preferences.appearanceMode == "Dark"
            ? "Light"
            : "Dark"
          session.setPreference(\.appearanceMode, to: next)
        }
        Button("Sign out", role: .destructive, action: onSignOut)
      } label: {
        DemoProfileAvatarView(size: 28)
      }
      .accessibilityLabel("Profile menu")
    }
  }

  var unreadNotificationCount: Int {
    session.notifications.filter { !$0.isRead }.count
  }
}
