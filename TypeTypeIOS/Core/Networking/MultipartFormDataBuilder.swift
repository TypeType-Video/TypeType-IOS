import Foundation

struct MultipartFormData {
  let contentType: String
  let body: Data

  init(
    fieldName: String,
    fileName: String,
    mediaType: String,
    data: Data
  ) {
    let boundary = "Boundary-\(UUID().uuidString)"
    contentType = "multipart/form-data; boundary=\(boundary)"
    var body = Data()
    body.append(Data("--\(boundary)\r\n".utf8))
    body.append(
      Data(
        (
          "Content-Disposition: form-data; "
            + "name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"
        ).utf8
      )
    )
    body.append(Data("Content-Type: \(mediaType)\r\n\r\n".utf8))
    body.append(data)
    body.append(Data("\r\n--\(boundary)--\r\n".utf8))
    self.body = body
  }

  init(contentType: String, body: Data) {
    self.contentType = contentType
    self.body = body
  }
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
    try body.appendUTF8("--\(boundary)\r\n")
    try body.appendUTF8(
      "Content-Disposition: form-data; "
        + "name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"
    )
    try body.appendUTF8("Content-Type: \(mimeType)\r\n\r\n")
    body.append(fileData)
    try body.appendUTF8("\r\n--\(boundary)--\r\n")
    return MultipartFormData(
      contentType: "multipart/form-data; boundary=\(boundary)",
      body: body
    )
  }
}

struct MultipartFormFile {
  let contentType: String
  let fileURL: URL

  init(
    sourceURL: URL,
    fieldName: String,
    fileName: String,
    mediaType: String
  ) throws {
    let boundary = "Boundary-\(UUID().uuidString)"
    contentType = "multipart/form-data; boundary=\(boundary)"
    fileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("typetype-\(UUID().uuidString)")
      .appendingPathExtension("multipart")

    guard FileManager.default.createFile(
      atPath: fileURL.path,
      contents: nil
    ) else {
      throw MultipartFormDataError.cannotCreateFile
    }

    do {
      let destination = try FileHandle(forWritingTo: fileURL)
      defer { try? destination.close() }
      try destination.write(
        contentsOf: Data("--\(boundary)\r\n".utf8)
      )
      try destination.write(
        contentsOf: Data(
          (
            "Content-Disposition: form-data; "
              + "name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"
          ).utf8
        )
      )
      try destination.write(
        contentsOf: Data("Content-Type: \(mediaType)\r\n\r\n".utf8)
      )

      let source = try FileHandle(forReadingFrom: sourceURL)
      defer { try? source.close() }
      while let chunk = try source.read(upToCount: 1_048_576),
        !chunk.isEmpty {
        try destination.write(contentsOf: chunk)
      }
      try destination.write(
        contentsOf: Data("\r\n--\(boundary)--\r\n".utf8)
      )
    } catch {
      try? FileManager.default.removeItem(at: fileURL)
      throw error
    }
  }
}

private extension Data {
  mutating func appendUTF8(_ value: String) throws {
    guard let encoded = value.data(using: .utf8) else {
      throw MultipartFormDataError.invalidUTF8
    }
    append(encoded)
  }
}

private enum MultipartFormDataError: Error {
  case invalidUTF8
  case cannotCreateFile
}
