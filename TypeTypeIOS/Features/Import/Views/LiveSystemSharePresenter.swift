import UIKit

enum LiveSystemSharePresenter {
  @MainActor
  static func present(_ url: URL) {
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
      var top = scene.keyWindow?.rootViewController
    else { return }
    while let presented = top.presentedViewController {
      top = presented
    }
    let activity = UIActivityViewController(
      activityItems: [url],
      applicationActivities: nil
    )
    top.present(activity, animated: true)
  }
}
