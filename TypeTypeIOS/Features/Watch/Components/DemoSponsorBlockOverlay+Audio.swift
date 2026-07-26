extension DemoSponsorBlockOverlay {
  func restoreAudio() {
    guard didMute else { return }
    controller.player.isMuted = false
    didMute = false
  }
}
