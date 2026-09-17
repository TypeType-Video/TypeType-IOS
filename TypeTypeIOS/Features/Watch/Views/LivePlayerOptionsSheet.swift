import SwiftUI

struct LivePlayerOptionsSheet: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var coordinator: LivePlaybackCoordinator
  @ObservedObject var bulletCommentStore: LiveBulletCommentStore
  @Binding var cinemaMode: Bool
  @Environment(\.dismiss) private var dismiss

  init(
    controller: LivePlayerController,
    coordinator: LivePlaybackCoordinator,
    cinemaMode: Binding<Bool>
  ) {
    self.controller = controller
    self.coordinator = coordinator
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
      }
      .accessibilityIdentifier("live.player.options-sheet")
      .navigationTitle("Player options")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
    .presentationDetents([.large])
  }
}
