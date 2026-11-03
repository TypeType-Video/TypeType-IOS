import UIKit

extension LivePictureInPictureDriver {
  func hasPoster(for url: URL?) -> Bool {
    url == nil || poster?.url == url
  }

  func loadPoster(url: URL?) async {
    guard let url, poster?.url != url else { return }
    let posterStart = DispatchTime.now()
    defer {
      let ms = Int(Double(DispatchTime.now().uptimeNanoseconds - posterStart.uptimeNanoseconds) / 1e6)
      AppLogger.playback.info("pip timing: poster took \(ms, privacy: .public)ms")
      Self.lastTimingLog = "poster \(ms)ms | " + Self.lastTimingLog
    }
    // A slow poster must not hold the PiP start: race the fetch against a short budget.
    let image: UIImage? = await withTaskGroup(
      of: UIImage?.self
    ) { group in
      group.addTask {
        guard let (data, _) = try? await URLSession.shared.data(from: url)
        else { return nil }
        return UIImage(data: data)
      }
      group.addTask {
        try? await Task.sleep(for: .milliseconds(1_200))
        return nil
      }
      let first = await group.next() ?? nil
      group.cancelAll()
      return first
    }
    guard let image, let cgImage = image.cgImage else { return }
    poster = (url, cgImage)
    applyPoster()
  }

  func applyPoster() {
    guard let poster else { return }
    contentLayer?.contents = poster.image
    contentLayer?.contentsGravity = .resizeAspect
  }
}
