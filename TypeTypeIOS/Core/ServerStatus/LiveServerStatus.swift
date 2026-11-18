import Foundation

struct LiveServerNotice: Decodable, Equatable {
  enum Kind: String, Decodable {
    case restart, update, maintenance
  }

  let kind: Kind
  let message: String?
  let resumeInSeconds: Int?
  let issuedAt: Int64?

  var trimmedMessage: String? {
    message.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
  }
}

struct LiveServerHello: Decodable, Equatable {
  let bootID: String
  let notice: LiveServerNotice?

  private enum CodingKeys: String, CodingKey {
    case notice
    case bootID = "bootId"
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    bootID = try values.decode(String.self, forKey: .bootID)
    notice = try? values.decodeIfPresent(LiveServerNotice.self, forKey: .notice)
  }
}

struct LiveServerStatus: Equatable {
  enum Phase: Equatable {
    case online, restarting, unreachable
  }

  var connected = true
  var phase = Phase.online
  var notice: LiveServerNotice?
  var bootID: String?
  var resumes = 0

  mutating func greeted(_ hello: LiveServerHello) {
    let restarting = hello.notice?.kind == .restart
    let recovered = phase != .online || (bootID != nil && bootID != hello.bootID)
    connected = true
    bootID = hello.bootID
    notice = hello.notice
    phase = restarting ? .restarting : .online
    if !restarting, recovered { resumes += 1 }
  }

  mutating func announced(_ notice: LiveServerNotice) {
    self.notice = notice
    if notice.kind == .restart { phase = .restarting }
  }

  mutating func cleared() {
    notice = nil
  }

  mutating func lost() {
    connected = false
  }

  mutating func lossConfirmed() {
    guard !connected, phase == .online else { return }
    phase = .unreachable
  }

  // The stream answered without a hello, as behind a proxy that buffers it: every other request gets through.
  mutating func reached() {
    guard !connected else { return }
    connected = true
    if phase == .unreachable {
      phase = .online
      resumes += 1
    }
  }
}
