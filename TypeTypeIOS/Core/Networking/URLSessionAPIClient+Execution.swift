import Foundation

extension URLSessionAPIClient {
  func execute(_ request: URLRequest, media: Bool = false) async throws -> Data {
    let startedAt = DispatchTime.now().uptimeNanoseconds
    do {
      try DebugNetworkOutage.check()
      let (data, response) = media
        ? try await mediaSession.data(for: request, delegate: mediaTaskPriority)
        : try await session.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        await recordDiagnostic(
          request,
          statusCode: nil,
          requestID: nil,
          startedAt: startedAt
        )
        throw NetworkError.invalidResponse
      }
      await recordDiagnostic(
        request,
        statusCode: http.statusCode,
        requestID: http.value(forHTTPHeaderField: "X-Request-Id"),
        startedAt: startedAt
      )
      captureRefreshCookie(from: http)
      guard (200...299).contains(http.statusCode) else {
        throw NetworkError.statusCode(
          http.statusCode,
          errorMessage(from: data)
        )
      }
      return data
    } catch let error as NetworkError {
      throw error
    } catch is CancellationError {
      throw CancellationError()
    } catch let error as URLError where error.code == .cancelled {
      // A cancelled task is not a network failure: no retry, no fallback, no diagnostic.
      throw CancellationError()
    } catch {
      await recordDiagnostic(
        request,
        statusCode: nil,
        requestID: nil,
        startedAt: startedAt
      )
      throw NetworkError.transport
    }
  }

  func executeUpload(
    _ request: URLRequest,
    from fileURL: URL
  ) async throws -> Data {
    let startedAt = DispatchTime.now().uptimeNanoseconds
    do {
      let (data, response) = try await session.upload(
        for: request,
        fromFile: fileURL
      )
      guard let http = response as? HTTPURLResponse else {
        await recordDiagnostic(
          request,
          statusCode: nil,
          requestID: nil,
          startedAt: startedAt
        )
        throw NetworkError.invalidResponse
      }
      await recordDiagnostic(
        request,
        statusCode: http.statusCode,
        requestID: http.value(forHTTPHeaderField: "X-Request-Id"),
        startedAt: startedAt
      )
      guard (200...299).contains(http.statusCode) else {
        throw NetworkError.statusCode(
          http.statusCode,
          errorMessage(from: data)
        )
      }
      return data
    } catch let error as NetworkError {
      throw error
    } catch is CancellationError {
      throw CancellationError()
    } catch let error as URLError where error.code == .cancelled {
      throw CancellationError()
    } catch {
      await recordDiagnostic(
        request,
        statusCode: nil,
        requestID: nil,
        startedAt: startedAt
      )
      throw NetworkError.transport
    }
  }

  func executeDownload(
    _ request: URLRequest
  ) async throws -> URL {
    let startedAt = DispatchTime.now().uptimeNanoseconds
    do {
      let (fileURL, response) = try await downloadSession.download(
        for: request
      )
      guard let http = response as? HTTPURLResponse else {
        await recordDiagnostic(
          request,
          statusCode: nil,
          requestID: nil,
          startedAt: startedAt
        )
        throw NetworkError.invalidResponse
      }
      await recordDiagnostic(
        request,
        statusCode: http.statusCode,
        requestID: http.value(forHTTPHeaderField: "X-Request-Id"),
        startedAt: startedAt
      )
      guard (200...299).contains(http.statusCode) else {
        let data = (try? Data(contentsOf: fileURL)) ?? Data()
        throw NetworkError.statusCode(
          http.statusCode,
          errorMessage(from: data)
        )
      }
      return fileURL
    } catch let error as NetworkError {
      throw error
    } catch is CancellationError {
      throw CancellationError()
    } catch let error as URLError where error.code == .cancelled {
      throw CancellationError()
    } catch {
      await recordDiagnostic(
        request,
        statusCode: nil,
        requestID: nil,
        startedAt: startedAt
      )
      throw NetworkError.transport
    }
  }
}

extension URLSessionAPIClient {
  // No 120 s resource timeout here: it cuts large artifacts mid-transfer. `configuration` returns a copy.
  static func makeDownloadSession(like session: URLSession) -> URLSession {
    let configuration = session.configuration
    configuration.timeoutIntervalForRequest = 600
    configuration.timeoutIntervalForResource = 7_200
    configuration.waitsForConnectivity = true
    return URLSession(
      configuration: configuration,
      delegate: DownloadRedirectCleaner(),
      delegateQueue: nil
    )
  }
}

// Artifacts redirect to presigned URLs on the same host: drop the API credentials, signed URLs reject them.
final class DownloadRedirectCleaner: NSObject, URLSessionTaskDelegate {
  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping (URLRequest?) -> Void
  ) {
    var clean = request
    clean.setValue(nil, forHTTPHeaderField: "Authorization")
    clean.setValue(nil, forHTTPHeaderField: "Cookie")
    completionHandler(clean)
  }
}
