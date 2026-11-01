import Darwin
import Foundation

enum LiveLocalNetworkAddress {
  // en0 is the Wi-Fi interface on iPhone and iPad; AirPlay receivers reach the device through it.
  static func wifiIPv4() -> String? {
    var first: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&first) == 0, let first else { return nil }
    defer { freeifaddrs(first) }
    for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
      let entry = pointer.pointee
      let flags = Int32(entry.ifa_flags)
      guard String(cString: entry.ifa_name) == "en0",
        let address = entry.ifa_addr,
        address.pointee.sa_family == UInt8(AF_INET),
        flags & IFF_UP != 0, flags & IFF_RUNNING != 0
      else {
        continue
      }
      var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
      guard getnameinfo(
        address, socklen_t(address.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST
      ) == 0 else {
        continue
      }
      return String(cString: host)
    }
    return nil
  }
}
