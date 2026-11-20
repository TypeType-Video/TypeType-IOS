import SwiftUI

struct LiveTwitchLinkCard: View {
  let title: LocalizedStringKey
  let message: LocalizedStringKey
  var systemImage = "person.crop.circle.badge.plus"
  var tint = Color.purple

  var body: some View {
    NavigationLink(value: LiveTwitchRoute.linkAccount) {
      HStack(spacing: 14) {
        Image(systemName: systemImage)
          .font(.title2)
          .foregroundStyle(tint)
          .frame(width: 44, height: 44)
          .background(tint.opacity(0.15), in: Circle())
        VStack(alignment: .leading, spacing: 2) {
          Text(title).font(.subheadline.weight(.semibold))
          Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
        }
        Spacer(minLength: 0)
        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
      }
      .padding(14)
      .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityHint(Text("Opens Linked accounts."))
  }
}
