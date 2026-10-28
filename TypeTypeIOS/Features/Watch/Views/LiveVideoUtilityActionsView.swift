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
        LiveShareAsLinkButton(
          typeTypeURL: shareURL,
          originalURL: LiveShareURLBuilder.original(
            sourceURL: video.url
          )
        ) {
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
    HStack(spacing: 6) {
      Image(systemName: symbol)
        .font(.title3.weight(.regular))

      Text(title)
        .font(.footnote.weight(.medium))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity)
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
