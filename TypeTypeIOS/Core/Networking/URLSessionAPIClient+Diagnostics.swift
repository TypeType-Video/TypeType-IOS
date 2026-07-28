import Foundation

extension URLSessionAPIClient {
  func recordDiagnostic(
    _ request: URLRequest,
    statusCode: Int?,
    requestID: String?,
    startedAt: UInt64
  ) async {
    guard let diagnosticsStore,
      let scope = diagnosticScopeProvider(),
      let requestURL = request.url,
      let baseURL = serverURLProvider()
    else {
      return
    }
    let elapsed = DispatchTime.now().uptimeNanoseconds
      .saturatingSubtract(startedAt) / 1_000_000
    await diagnosticsStore.record(
      scope: scope,
      method: request.httpMethod ?? "OTHER",
      requestURL: requestURL,
      baseURL: baseURL,
      statusCode: statusCode,
      durationMilliseconds: Int64(min(elapsed, UInt64(Int64.max))),
      requestID: requestID
    )
  }
}

private extension UInt64 {
  func saturatingSubtract(_ value: UInt64) -> UInt64 {
    self >= value ? self - value : 0
  }
}
