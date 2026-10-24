import SwiftUI

struct LiveVideoUtilityActionsView: View {
  let video: LiveVideoItem
  let dependencies: AppDependencies
  @ObservedObject var playerController: LivePlayerController
  @State private var presentsDownload = false
  @State private var presentsReport = false

  var body: some View {
    HStack(spacing: 10) {
      if let shareURL {
        ShareLink(item: shareURL) {
          actionLabel("Share", symbol: "square.and.arrow.up")
        }
        .buttonStyle(LiveChipButtonStyle())
      }

      Button {
        presentsDownload = true
      } label: {
        actionLabel("Download", symbol: "arrow.down.circle")
      }
      .buttonStyle(LiveChipButtonStyle())

      if canReport {
        Button {
          presentsReport = true
        } label: {
          actionLabel(
            "Report",
            symbol: "exclamationmark.bubble"
          )
        }
        .buttonStyle(LiveChipButtonStyle())
      }

      if playerController.supportsBulletComments {
        LiveDanmakuQuickControlsView(
          controller: playerController
        )
      }
    }
    .sheet(isPresented: $presentsDownload) {
      LiveDownloadSheet(
        video: video,
        dependencies: dependencies
      )
    }
    .sheet(isPresented: $presentsReport) {
      NavigationStack {
        LiveReportIssueView(
          service: dependencies.bugReportsService,
          videoURL: video.url
        )
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Close") { presentsReport = false }
          }
        }
      }
    }
  }

  private func actionLabel(
    _ title: String,
    symbol: String
  ) -> some View {
    VStack(spacing: 5) {
      Image(systemName: symbol)
        .font(.title3.weight(.medium))
      Text(title)
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
      .frame(maxWidth: .infinity)
      .frame(minHeight: 48)
  }

  private var shareURL: URL? {
    LiveShareURLBuilder.video(
      serverURL: dependencies.serverStore.selectedServer()?.baseURL,
      sourceURL: video.url
    )
  }

  private var canReport: Bool {
    guard let serverID = dependencies.serverStore.selectedServerID(),
      let session = dependencies.sessionStore.session(
        forServerID: serverID
      )
    else {
      return false
    }
    return session.accountIdentifier != nil
  }
}
