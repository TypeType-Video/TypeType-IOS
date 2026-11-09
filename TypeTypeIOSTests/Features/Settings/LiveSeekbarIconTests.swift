import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import TypeTypeIOS

final class LiveSeekbarIconTests: XCTestCase {
  func testSettingsPickTheIconLikeTheOtherClients() throws {
    var settings = LiveSettings()
    XCTAssertEqual(LiveSeekbarIcon(settings: settings), .typeType)
    settings.seekbarIcon = "none"
    XCTAssertEqual(LiveSeekbarIcon(settings: settings), .plain)
    settings.seekbarIcon = "custom"
    XCTAssertEqual(LiveSeekbarIcon(settings: settings), .typeType)
    XCTAssertEqual(LiveSeekbarIconChoice.shown(for: settings), .typeType)
    settings.seekbarIconUrl = "https://own.example/seekbar-icon/u1/v2"
    let url = try XCTUnwrap(URL(string: "https://own.example/seekbar-icon/u1/v2"))
    XCTAssertEqual(LiveSeekbarIcon(settings: settings), .custom(url))
    settings.seekbarIcon = "unknown"
    XCTAssertEqual(LiveSeekbarIcon(settings: settings), .typeType)
  }

  func testSettingsWithoutTheIconKeysStillDecode() throws {
    let settings = try JSONDecoder().decode(LiveSettings.self, from: Data(Self.settingsJSON(extra: "").utf8))
    XCTAssertNil(settings.seekbarIcon)
    let withIcon = try JSONDecoder().decode(
      LiveSettings.self,
      from: Data(Self.settingsJSON(extra: #","seekbarIcon":"custom","seekbarIconUrl":"/seekbar-icon/u/1""#).utf8)
    )
    XCTAssertEqual(withIcon.seekbarIcon, "custom")
    XCTAssertEqual(withIcon.seekbarIconUrl, "/seekbar-icon/u/1")
  }

  func testUploadKeepsSupportedImagesAsTheyAre() throws {
    let png = try Self.image(.png, frames: 1)
    XCTAssertEqual(LiveSeekbarIconPayload.make(from: png), .ready(png, mediaType: "image/png"))
    let gif = try Self.image(.gif, frames: 3)
    XCTAssertEqual(LiveSeekbarIconPayload.make(from: gif), .ready(gif, mediaType: "image/gif"))
    XCTAssertEqual(LiveSeekbarIconPayload.mediaType(of: Data("RIFF\0\0\0\0WEBPVP8 ".utf8)), "image/webp")
  }

  func testUploadShrinksALargeStillImageAndRefusesALargeAnimation() throws {
    let png = try Self.image(.png, frames: 1, side: 400)
    guard case let .ready(data, mediaType) = LiveSeekbarIconPayload.make(from: png, maxBytes: png.count - 1) else {
      return XCTFail("a still image should be resized")
    }
    XCTAssertEqual(mediaType, "image/png")
    XCTAssertLessThan(data.count, png.count)
    let gif = try Self.image(.gif, frames: 3)
    XCTAssertEqual(LiveSeekbarIconPayload.make(from: gif, maxBytes: 10), .tooLarge)
    XCTAssertEqual(LiveSeekbarIconPayload.make(from: Data("not an image".utf8)), .unsupported)
  }

  func testAnimatedIconsKeepTheirFrames() throws {
    let gif = try Self.image(.gif, frames: 3)
    let image = try XCTUnwrap(LiveSeekbarIconLoader.decode(gif))
    XCTAssertEqual(image.images?.count, 3)
    XCTAssertEqual(image.duration, 0.3, accuracy: 0.01)
    XCTAssertNil(try XCTUnwrap(LiveSeekbarIconLoader.decode(Self.image(.png, frames: 1))).images)
  }

  private static func image(_ type: UTType, frames: Int, side: Int = 32) throws -> Data {
    let output = NSMutableData()
    let destination = try XCTUnwrap(CGImageDestinationCreateWithData(output, type.identifier as CFString, frames, nil))
    let context = try XCTUnwrap(
      CGContext(
        data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    )
    for frame in 0..<frames {
      for y in 0..<side {
        for x in 0..<side {
          context.setFillColor(red: CGFloat((x * 7 + frame * 40) % 255) / 255, green: CGFloat(y) / CGFloat(side), blue: 0.5, alpha: 1)
          context.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }
      }
      let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.1]] as CFDictionary
      CGImageDestinationAddImage(destination, try XCTUnwrap(context.makeImage()), properties)
    }
    XCTAssertTrue(CGImageDestinationFinalize(destination))
    return output as Data
  }

  private static func settingsJSON(extra: String) -> String {
    let encoded = try? JSONEncoder().encode(LiveSettings())
    let base = encoded.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    return String(base.dropLast()) + extra + "}"
  }
}
