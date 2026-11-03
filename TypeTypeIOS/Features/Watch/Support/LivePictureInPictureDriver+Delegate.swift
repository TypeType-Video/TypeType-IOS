import AVKit

extension LivePictureInPictureDriver: AVPictureInPictureControllerDelegate {
  nonisolated func pictureInPictureControllerDidStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      didStartConfirmed = true
      // Late confirms arrive after verification gave up: the window is up and the return path needs the flag.
      markEngaged(true)
      if let requestedAt = startRequestedAt {
        let ms = Int(Double(DispatchTime.now().uptimeNanoseconds - requestedAt.uptimeNanoseconds) / 1e6)
        AppLogger.playback
          .info("pip timing: request to confirmed took \(ms, privacy: .public)ms")
        Self.lastTimingLog = "confirm \(ms)ms | " + Self.lastTimingLog
      }
      onChange?()
    }
  }

  nonisolated func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    let reason = error.localizedDescription
    Task { @MainActor [weak self] in
      guard let self else { return }
      AppLogger.playback.error("pip driver: failed to start: \(reason, privacy: .public)")
      markEngaged(false)
      contentLayer?.isHidden = true
      onChange?()
    }
  }

  nonisolated func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
      completionHandler: @escaping (Bool) -> Void
  ) {
    Task { @MainActor [weak self] in
      guard let self else {
        completionHandler(false)
        return
      }
      isRestoring = true
      AppLogger.playback.info("pip driver: restore requested")
      onRestore?()
      completionHandler(true)
    }
  }

  nonisolated func pictureInPictureControllerDidStopPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      markEngaged(false)
      contentLayer?.isHidden = true
      controlsRefreshPending = true
      let wasRestoring = isRestoring
      isRestoring = false
      AppLogger.playback
        .info("pip driver: did stop, restoring=\(wasRestoring, privacy: .public)")
      onChange?()
      let onInline = self.onInline
      self.onInline = nil
      if wasRestoring {
        onInline?()
      } else {
        onClose?()
      }
    }
  }
}
