import SwiftUI

struct DemoMoreView: View {
  @Environment(\.themePalette) private var palette
  let onSignOut: () -> Void
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 24) {
          NavigationLink {
            DemoProfileView()
          } label: {
            profileCard
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("demo.more.profile")
          DemoMoreContentSection()
          preferencesSection
          administrationSection
          supportSection

          Button("Sign out", role: .destructive, action: onSignOut)
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 30)
      }
      .background(palette.groupedBackground)
      .navigationTitle("More")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(
        palette.groupedBackground.opacity(0.96),
        for: .navigationBar
      )
    }
    .accessibilityIdentifier("demo.more.screen")
  }

  private var profileCard: some View {
    HStack(spacing: 14) {
      DemoProfileAvatarView(size: 66)

      VStack(alignment: .leading, spacing: 3) {
        Text(session.profileDisplayName)
          .font(.headline)
          .foregroundStyle(.primary)
        Text("@\(session.profileUsername) · TypeType Beta")
          .font(.caption)
          .foregroundStyle(.secondary)
        Label("Mock data · Offline", systemImage: "checkmark.circle.fill")
          .font(.caption2.weight(.medium))
          .foregroundStyle(.green)
      }
      Spacer()
    }
    .padding(16)
    .background(palette.groupedSurface)
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }

}
