import BackgroundTasks
import Foundation

@MainActor
final class LiveBackgroundRefreshCoordinator {
  static let taskIdentifier = "dev.typetype.ios.notifications-refresh"

  private let scheduler: BGTaskScheduler
  private weak var dependencies: AppDependencies?
  private var isRegistered = false

  init(scheduler: BGTaskScheduler = .shared) {
    self.scheduler = scheduler
  }

  func configure(dependencies: AppDependencies) {
    self.dependencies = dependencies
  }

  func registerIfNeeded() {
    guard !isRegistered else { return }
    isRegistered = true
    scheduler.register(
      forTaskWithIdentifier: Self.taskIdentifier,
      using: nil
    ) { [weak self] task in
      guard let self,
        let refreshTask = task as? BGAppRefreshTask
      else {
        task.setTaskCompleted(success: false)
        return
      }
      Task { @MainActor in
        await self.handle(refreshTask)
      }
    }
  }

  func scheduleRefresh(after seconds: TimeInterval = 15 * 60) {
    let request = BGAppRefreshTaskRequest(
      identifier: Self.taskIdentifier
    )
    request.earliestBeginDate = Date().addingTimeInterval(seconds)
    do {
      try scheduler.submit(request)
    } catch {
      AppLogger.app.failure("Scheduling the notifications refresh", error)
    }
  }

  func handle(_ task: BGAppRefreshTask) async {
    scheduleRefresh()
    let refreshTask = Task { [weak dependencies] in
      await dependencies?.notificationCenter.refresh()
    }
    task.expirationHandler = {
      refreshTask.cancel()
    }
    await refreshTask.value
    task.setTaskCompleted(success: !refreshTask.isCancelled)
  }
}
