import SwiftUI

struct LiveHistoryCard: View {
  let item: LiveHistoryItem
  let dependencies: AppDependencies
  @ObservedObject private var deArrowStore: LiveDeArrowStore
  let onSelect: () -> Void
  let onChannel: () -> Void
  let onRemove: () -> Void

  init(
    item: LiveHistoryItem,
    dependencies: AppDependencies,
    onSelect: @escaping () -> Void,
    onChannel: @escaping () -> Void,
    onRemove: @escaping () -> Void
  ) {
    self.item = item
    self.dependencies = dependencies
    deArrowStore = dependencies.deArrowStore
    self.onSelect = onSelect
    self.onChannel = onChannel
    self.onRemove = onRemove
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      Button(action: onSelect) {
        ZStack(alignment: .bottomLeading) {
          LiveRemoteImage(url: branding.thumbnailURL)
            .aspectRatio(16 / 9, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
          ProgressView(value: item.progressFraction)
            .tint(DemoTheme.accent)
            .background(.black.opacity(0.4))
        }
        .clipShape(
          RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
      }
      .buttonStyle(.plain)

      HStack(alignment: .top, spacing: 10) {
        Button(action: onChannel) {
          LiveRemoteImage(url: item.avatarURL)
            .frame(width: 34, height: 34)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(item.channelName)")

        VStack(alignment: .leading, spacing: 3) {
          Button(action: onSelect) {
            Text(branding.title)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.primary)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
          }
          .buttonStyle(.plain)

          Button(action: onChannel) {
            Text(item.channelName)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)

          Text(item.watchedDate.formatted(
            date: .abbreviated,
            time: .shortened
          ))
          .font(.caption2)
          .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Spacer(minLength: 4)
        Menu {
          Button(
            "Remove from history",
            systemImage: "trash",
            role: .destructive,
            action: onRemove
          )
        } label: {
          LiveDotsGlyph()
        }
        .accessibilityLabel("History options")
      }
    }
    .liveVideoQuickActions(
      video: item.video,
      dependencies: dependencies,
      onOpenChannel: onChannel,
      removeLabel: "Remove from history",
      onRemove: onRemove
    )
    .accessibilityIdentifier("live.history.card")
    .task { await deArrowStore.prepare(item.video) }
  }

  private var branding: LiveVideoBranding {
    deArrowStore.branding(for: item.video)
  }
}
