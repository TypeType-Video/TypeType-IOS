import SwiftUI

extension ServerSetupView {
  var savedServers: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Saved instances")
        .font(.headline)

      ForEach(coordinator.servers) { server in
        HStack(spacing: 12) {
          Button {
            Task {
              await coordinator.selectServer(server)
            }
          } label: {
            HStack(spacing: 12) {
              Image(systemName: "server.rack")
                .font(.title3)
                .foregroundStyle(DemoTheme.accent)
                .frame(width: 32)
              VStack(alignment: .leading, spacing: 3) {
                Text(server.name)
                  .font(.subheadline.weight(.semibold))
                  .foregroundStyle(.primary)
                Text(server.baseURLString)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }
              Spacer()
              Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)

          Menu {
            Button(role: .destructive) {
              pendingRemoval = server
            } label: {
              Label("Remove instance", systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
              .font(.title3)
              .foregroundStyle(.secondary)
          }
          .accessibilityLabel("Options for \(server.name)")
        }

        if server.id != coordinator.servers.last?.id {
          Divider()
        }
      }
    }
    .liveCard()
  }
}

extension View {
  func liveCard() -> some View {
    padding(20)
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .strokeBorder(.primary.opacity(0.1))
      }
  }
}
