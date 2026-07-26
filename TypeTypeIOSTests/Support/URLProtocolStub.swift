import Foundation

final class URLProtocolStub: URLProtocol {
  typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

  private static let queue = DispatchQueue(
    label: "URLProtocolStub.queue"
  )
  private static var handler: Handler?

  static func register(_ handler: @escaping Handler) {
    queue.sync {
      self.handler = handler
    }
  }

  static func reset() {
    queue.sync {
      handler = nil
    }
  }

  static func bodyData(from request: URLRequest) throws -> Data? {
    if let body = request.httpBody {
      return body
    }
    guard let stream = request.httpBodyStream else {
      return nil
    }
    stream.open()
    defer { stream.close() }

    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 1_024)
    while stream.hasBytesAvailable {
      let count = stream.read(&buffer, maxLength: buffer.count)
      if count < 0 {
        throw stream.streamError ?? URLProtocolStubError.bodyReadFailed
      }
      if count == 0 {
        break
      }
      data.append(buffer, count: count)
    }
    return data
  }

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(
    for request: URLRequest
  ) -> URLRequest {
    request
  }

  override func startLoading() {
    do {
      guard let handler = Self.queue.sync(
        execute: { Self.handler }
      ) else {
        throw URLProtocolStubError.missingHandler
      }
      let (response, data) = try handler(request)
      client?.urlProtocol(
        self,
        didReceive: response,
        cacheStoragePolicy: .notAllowed
      )
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

private enum URLProtocolStubError: Error {
  case missingHandler
  case bodyReadFailed
}
