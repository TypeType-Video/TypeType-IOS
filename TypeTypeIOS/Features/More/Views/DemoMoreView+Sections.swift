import SwiftUI

extension DemoMoreView {
  var preferencesSection: some View {
    DemoMoreSectionCard("Preferences") {
      destinationRow(
        "Playback",
        subtitle: "Quality, autoplay, audio boost",
        systemImage: "play.rectangle.fill",
        tint: .red
      ) {
        DemoPlaybackSettingsView()
      }
      divider
      destinationRow(
        "Video",
        subtitle: "SponsorBlock, DeArrow, comments",
        systemImage: "slider.horizontal.3",
        tint: .orange
      ) {
        DemoVideoSettingsView()
      }
      divider
      destinationRow(
        "Discovery & services",
        subtitle: "YouTube, NicoNico, BiliBili",
        systemImage: "dot.radiowaves.left.and.right",
        tint: .blue
      ) {
        DemoDiscoverySettingsView()
      }
      divider
      destinationRow(
        "Language",
        subtitle: "Audio and subtitle defaults",
        systemImage: "captions.bubble.fill",
        tint: .cyan
      ) {
        DemoLanguageSettingsView()
      }
      divider
      destinationRow(
        "Appearance",
        subtitle: "Theme and accent",
        systemImage: "paintbrush.fill",
        tint: .purple
      ) {
        DemoAppearanceView()
      }
      divider
      destinationRow(
        "Privacy",
        subtitle: "History and blocked content",
        systemImage: "hand.raised.fill",
        tint: .indigo
      ) {
        DemoPrivacyView()
      }
    }
  }

  var supportSection: some View {
    DemoMoreSectionCard("Support") {
      destinationRow(
        "Report a problem",
        systemImage: "ladybug.fill",
        tint: .green
      ) {
        DemoBugReportView()
      }
      divider
      destinationRow(
        "About TypeType",
        subtitle: "Open-source video client",
        systemImage: "info.circle.fill",
        tint: .gray
      ) {
        DemoAboutView()
      }
    }
  }

  var administrationSection: some View {
    DemoMoreSectionCard("Administration") {
      destinationRow(
        "Admin console",
        subtitle: "Settings, allow list, users, sessions, issues",
        systemImage: "lock.shield.fill",
        tint: .mint
      ) {
        DemoAdminConsoleView()
      }
    }
  }

  var divider: some View {
    Divider().padding(.leading, 45)
  }

  func destinationRow<Destination: View>(
    _ title: String,
    subtitle: String? = nil,
    systemImage: String,
    tint: Color,
    @ViewBuilder destination: () -> Destination
  ) -> some View {
    NavigationLink {
      destination()
    } label: {
      DemoMoreRow(
        title,
        subtitle: subtitle,
        systemImage: systemImage,
        tint: tint,
        showsChevron: true
      )
      .padding(.vertical, 11)
    }
    .buttonStyle(.plain)
  }
}
