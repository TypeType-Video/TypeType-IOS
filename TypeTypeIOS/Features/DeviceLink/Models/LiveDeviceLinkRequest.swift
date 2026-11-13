import Foundation

struct LiveDeviceLinkRequest: Decodable, Equatable {
  let userCode: String
  let deviceName: String

  private enum CodingKeys: String, CodingKey {
    case userCode, deviceName
  }

  init(userCode: String, deviceName: String) {
    self.userCode = userCode
    self.deviceName = deviceName
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    userCode = try container.decode(String.self, forKey: .userCode)
    deviceName = try container.decodeIfPresent(String.self, forKey: .deviceName) ?? ""
  }

  static func normalized(_ code: String) -> String {
    String(code.uppercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") })
  }
}
