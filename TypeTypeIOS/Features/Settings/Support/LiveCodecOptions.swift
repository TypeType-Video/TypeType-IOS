import CoreMedia
import VideoToolbox

enum LiveCodecOptions {
  static let auto = "recommended"

  static func available(
    decodesInHardware: (CMVideoCodecType) -> Bool = VTIsHardwareDecodeSupported
  ) -> [(String, String)] {
    var options = [(auto, "Auto")]
    if decodesInHardware(kCMVideoCodecType_AV1) {
      options.append(("av1", "AV1"))
    }
    if decodesInHardware(kCMVideoCodecType_VP9) {
      options.append(("vp9", "VP9"))
    }
    options.append(("h264", "H.264"))
    return options
  }

  static func shown(_ stored: String, among options: [(String, String)]) -> String {
    options.contains { $0.0 == stored } ? stored : auto
  }
}
