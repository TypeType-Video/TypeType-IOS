import Foundation

protocol APIClient {
  func request<T: Decodable>(
    _ endpoint: APIEndpoint,
    as type: T.Type
  ) async throws -> T
  func request(_ endpoint: APIEndpoint) async throws
  func requestData(_ endpoint: APIEndpoint) async throws -> Data
}
