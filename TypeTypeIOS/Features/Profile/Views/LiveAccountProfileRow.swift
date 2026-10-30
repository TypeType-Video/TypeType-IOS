import SwiftUI

struct LiveAccountProfileRow: View {
  let profile: AccountProfileItem
  let isSwitching: Bool
  let onSwitch: () -> Void
  let onSetDefault: () -> Void
  let onRename: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: profile.isActive ? "checkmark.circle.fill" : "person.crop.circle")
        .font(.title3)
        .foregroundStyle(profile.isActive ? Color.accentColor : Color.secondary)
      VStack(alignment: .leading, spacing: 3) {
        Text(profile.name)
          .font(.body.weight(.semibold))
        HStack(spacing: 6) {
          if profile.isDefault {
            tag("Default", fill: Color.secondary.opacity(0.2))
          }
          if profile.isActive {
            tag("Active", fill: Color.accentColor.opacity(0.16))
          }
        }
      }
      Spacer()
      if isSwitching && !profile.isActive {
        ProgressView()
      }
    }
    .padding(.vertical, 2)
    .contentShape(Rectangle())
    .onTapGesture {
      onSwitch()
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      if !profile.isActive {
        Button(role: .destructive) {
          onDelete()
        } label: {
          Label("Delete", systemImage: "trash")
        }
      }
      Button {
        onSetDefault()
      } label: {
        Label("Default", systemImage: "star")
      }
      .tint(.orange)
      Button {
        onRename()
      } label: {
        Label("Rename", systemImage: "pencil")
      }
      .tint(.blue)
    }
    .contextMenu {
      if !profile.isActive {
        Button {
          onSwitch()
        } label: {
          Label("Switch to profile", systemImage: "arrow.left.arrow.right.circle")
        }
      }
      Button {
        onSetDefault()
      } label: {
        Label("Set as default", systemImage: "star")
      }
      Button {
        onRename()
      } label: {
        Label("Rename", systemImage: "pencil")
      }
      if !profile.isActive {
        Button(role: .destructive) {
          onDelete()
        } label: {
          Label("Delete profile", systemImage: "trash")
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(profile.name)
    .accessibilityValue("Profile")
    .accessibilityHint(
      profile.isActive
        ? LocalizedStringKey("This profile is active.")
        : LocalizedStringKey("Switch to profile")
    )
    .accessibilityAddTraits(profile.isActive ? [] : .isButton)
  }

  private func tag(_ title: LocalizedStringKey, fill: Color) -> some View {
    Text(title)
      .font(.caption.weight(.semibold))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(fill, in: Capsule())
  }
}
