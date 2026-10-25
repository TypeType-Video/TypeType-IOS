import SwiftUI

struct LivePlayerOptionsSheet: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let dependencies: AppDependencies
  @ObservedObject var bulletCommentStore: LiveBulletCommentStore
  @Binding var cinemaMode: Bool
  @Environment(\.dismiss) private var dismiss
  @State var presentsReport = false

  init(
    controller: LivePlayerController,
    coordinator: LivePlaybackCoordinator,
    dependencies: AppDependencies,
    cinemaMode: Binding<Bool>
  ) {
    self.controller = controller
    self.coordinator = coordinator
    self.dependencies = dependencies
    bulletCommentStore = controller.bulletCommentStore
    _cinemaMode = cinemaMode
  }

  var body: some View {
    NavigationStack {
      Form {
        playbackSection
        qualitySection
        tracksSection
        chaptersSection
        presentationSection
        communitySection
        streamInformationSection
        reportSection
      }
        .liveThemedList()
      .id(DemoTheme.renderToken)
      .accessibilityIdentifier("live.player.options-sheet")
      .navigationTitle("Player options")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
    .sheet(isPresented: $presentsReport) {
      NavigationStack {
        LiveReportIssueView(
          service: dependencies.bugReportsService,
          videoURL: coordinator.currentVideo?.url ?? ""
        )
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Close") { presentsReport = false }
          }
        }
      }
    }
    .presentationDetents([.large])
  }
}
