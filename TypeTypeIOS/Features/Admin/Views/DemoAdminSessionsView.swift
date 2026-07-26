import SwiftUI

struct DemoAdminSessionsView: View {
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    List {
      if !session.adminSettings.tracksActiveSessions {
        ContentUnavailableView(
          "Session tracking disabled",
          systemImage: "eye.slash",
          description: Text("Enable active sessions in instance settings.")
        )
      } else if session.adminSessions.isEmpty {
        ContentUnavailableView(
          "No active sessions",
          systemImage: "person.2.slash"
        )
      } else {
        ForEach(session.adminSessions) { item in
          VStack(alignment: .leading, spacing: 10) {
            HStack {
              VStack(alignment: .leading, spacing: 2) {
                Text(userName(item.userID))
                  .font(.headline)
                Text(item.device)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              Text(item.lastSeen)
                .font(.caption2)
                .foregroundStyle(.green)
            }
            if let video = item.video {
              HStack(spacing: 12) {
                DemoArtworkView(video: video)
                  .frame(width: 104, height: 60)
                  .clipShape(RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 5) {
                  Text(video.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                  ProgressView(value: item.position)
                }
              }
            } else {
              Label("Online · no active playback", systemImage: "circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 6)
        }
      }
    }
  }

  private func userName(_ userID: String) -> String {
    session.adminUsers.first { $0.id == userID }?.name ?? userID
  }
}
