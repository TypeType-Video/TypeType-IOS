import Foundation

actor TokenRefreshGate {
  private var inFlight: (
    staleToken: String,
    task: Task<String?, Never>
  )?
  private var latestResult: (
    staleToken: String,
    refreshedToken: String
  )?

  func refresh(
    staleToken: String,
    using handler: @escaping URLSessionAPIClient.TokenRefreshHandler
  ) async -> String? {
    if let latestResult, latestResult.staleToken == staleToken {
      return latestResult.refreshedToken
    }
    if let inFlight, inFlight.staleToken == staleToken {
      return await inFlight.task.value
    }

    let task = Task<String?, Never> {
      try? await handler(staleToken)
    }
    inFlight = (staleToken, task)
    let token = await task.value
    inFlight = nil
    if let token {
      latestResult = (staleToken, token)
    }
    return token
  }
}
