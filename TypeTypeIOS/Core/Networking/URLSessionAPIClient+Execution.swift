import Foundation

extension URLSessionAPIClient {
  func execute(_ request: URLRequest, media: Bool = false) async throws -> Data {
    let startedAt = DispatchTime.now().uptimeNanoseconds
    do {
      try DebugNetworkOutage.check()
      let (data, response) = media
        ? try await mediaSession.data(for: request, delegate: MediaTaskPriority.shared)
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
      let (fileURL, response) = try await session.download(for: request)
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
