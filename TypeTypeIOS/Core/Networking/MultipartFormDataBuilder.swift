import Foundation

struct MultipartFormData {
  let contentType: String
  let body: Data
}

struct MultipartFormDataBuilder {
  let fileURL: URL
  let fieldName: String
  let fileName: String
  let mimeType: String

  func build() throws -> MultipartFormData {
    let boundary = "Boundary-\(UUID().uuidString)"
    let fileData = try Data(contentsOf: fileURL)
    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
    body.append(fileData)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    return MultipartFormData(contentType: "multipart/form-data; boundary=\(boundary)", body: body)
  }
}
