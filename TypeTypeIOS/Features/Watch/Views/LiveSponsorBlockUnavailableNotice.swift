import SwiftUI

struct LiveSponsorBlockUnavailableNotice: ViewModifier {
  @ObservedObject var controller: LivePlayerController
  @Environment(\.liveToasts) private var toasts

  func body(content: Content) -> some View {
    content.onChange(of: controller.stream?.id) {
      guard controller.stream?.sponsorBlockUnavailable == true,
        controller.sponsorBlockMode != LiveSponsorBlockMode.disabled.rawValue
      else { return }
      toasts?.show(String(localized: "SponsorBlock is not responding, segments are not loaded for this video"), tone: .failure)
    }
  }
}
