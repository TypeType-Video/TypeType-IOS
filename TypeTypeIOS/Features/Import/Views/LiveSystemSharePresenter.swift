import UIKit

/// Presents the system share sheet from UIKit: the Liquid Glass sheet iOS
/// 26 shows for ShareLink. Wrapping UIActivityViewController in a SwiftUI
/// .sheet renders a plain page instead.
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
