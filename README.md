<!-- markdownlint-disable MD033 MD041 -->

<div align="center">
  <img src="https://raw.githubusercontent.com/TypeType-Video/TypeType/main/assets/banner.svg" alt="TypeType" width="100%">
  <h1>TypeType iOS</h1>
  <p>A native TypeType experience for iPhone and iPad.</p>
</div>

You want to know the current position of TypeType about AI ? Go check [this](https://github.com/TypeType-Video/TypeType/blob/dev/AI_TRANSPARENCY.md).

<div align="center">

[![iOS](https://github.com/TypeType-Video/TypeType-IOS/actions/workflows/ios.yml/badge.svg?branch=main)](https://github.com/TypeType-Video/TypeType-IOS/actions/workflows/ios.yml)
[![MPL 2.0](https://img.shields.io/badge/license-MPL--2.0-orange.svg)](LICENSE)
[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-000000.svg?logo=apple)](project.yml)
[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-F05138.svg?logo=swift&logoColor=white)](project.yml)
[![TypeType](https://img.shields.io/badge/TypeType-ecosystem-7c3aed.svg)](https://github.com/TypeType-Video/TypeType)

</div>

TypeType iOS is the native SwiftUI client for
[TypeType](https://github.com/TypeType-Video/TypeType). It combines adaptive
iPhone and iPad navigation with AVKit playback, background audio, Picture in
Picture, offline media, and persistent access to a selected self-hosted
instance.

The client communicates exclusively with
[TypeType-Server](https://github.com/TypeType-Video/TypeType-Server). Media
extraction, YouTube session state, SABR playback sessions, synchronization,
downloads, recommendations, and authoritative user data remain server-side.

## iPhone

| Home | Search | Playlists | Watch |
| --- | --- | --- | --- |
| ![TypeType home on iPhone](assets/screenshots/iphone-home.png) | ![TypeType search on iPhone](assets/screenshots/iphone-search.png) | ![TypeType playlists on iPhone](assets/screenshots/iphone-playlists.png) | ![TypeType watch page on iPhone](assets/screenshots/iphone-player.png) |

## iPad

| Home | Watch |
| --- | --- |
| ![TypeType home on iPad](assets/screenshots/ipad-home.png) | ![TypeType watch page on iPad](assets/screenshots/ipad-player.png) |

The screenshots come directly from the current iPhone and iPad application
builds. Reproducible interface fixtures keep visual regressions independent
from changing public feeds.

## Features

- One adaptive SwiftUI interface for iPhone and iPad
- Instance setup, guest access, local accounts, OIDC, password reset, and
  Keychain-backed persistent sessions
- Account profiles with isolated server-side sessions
- Channel notification preferences when the instance enables push delivery
- Subscription groups with creation, management, filtering, and per-channel
  quick actions
- Home, multi-service search, channels, podcasts, subscriptions, history,
  playlists, favorites, and Watch Later
- YouTube, BiliBili, and NicoNico discovery with provider-aware playback and
  native NicoNico danmaku
- Queue, captions, chapters, SponsorBlock, DeArrow, comments, related videos,
  sleep timer, and playback-speed controls
- Player double-tap seek zones with native AVKit controls
- Server-backed audio and video downloads with persistent tracking and native
  offline playback
- Profile, imports, notifications, content controls, diagnostics, settings,
  and instance administration
- Dark and light appearances with Dynamic Type and VoiceOver-friendly controls

## Native playback

| Source | Native path |
| --- | --- |
| YouTube | TypeType SABR sessions, fragmented MP4 segments, bounded live and VOD buffers, native seeking, and selectable H.264/AAC tracks |
| BiliBili | Authenticated byte-range loading, SIDX indexing, separate audio/video adaptation to local HLS, and automatic source fallback |
| NicoNico | Provider media through AVKit with synchronized, configurable danmaku |
| Downloads | Validated local audio or video artifacts played directly with AVKit |

The application presents online media through the native player rather than a
WebView. Full-screen playback, Picture in Picture, mini-player transitions,
audio-only round trips, background audio, captions, queue state, and playback
progress share one controller. Downloaded artifacts use a dedicated offline
AVKit player.

Playback is designed to survive transient network failures. SABR window
requests are serialized and refreshed near the playback edge, interrupted
transport requests can recover without losing the timeline, and unstable
provider formats fall back to another compatible source.

> [!NOTE]
> TypeType iOS contains no extraction engine, browser player, or copied backend
> implementation. It consumes the TypeType-Server HTTP API and converts the
> server's media contracts into native AVFoundation and AVKit playback.

## Quality

The repository separates deterministic regression coverage from opt-in live
backend validation:

- Unit and contract tests cover networking, authentication, persistence,
  playback preparation, SABR windows, provider indexing, downloads, and state
  transitions.
- iPhone and iPad XCUITests cover complete interface journeys with reproducible
  content and screenshots.
- Live XCUITests exercise randomized YouTube, BiliBili, and NicoNico videos,
  long-form playback, full-screen round trips, audio-only transitions, process
  relaunches, provider fallback, and real transport interruptions.
- GitHub Actions runs the unit suite and builds the Release configuration for
  every push and pull request targeting `dev` or `main`.

## Stack

| Area | Technology |
| --- | --- |
| Language | Swift 5.10 |
| Platform | iOS 17+ |
| Interface | SwiftUI |
| Playback | AVFoundation and AVKit |
| Networking | URLSession |
| Persistence | Keychain and UserDefaults |
| Project generation | XcodeGen |
| Tests | XCTest and XCUITest |

## API contract

The client communicates with TypeType-Server over HTTPS, or local HTTP for a
private self-hosted instance. Documented endpoints follow the server
[OpenAPI specification](https://github.com/TypeType-Video/TypeType-Server/blob/dev/openapi.yaml);
integration work is also checked against the current server routes while that
published contract grows. No extraction engine or backend implementation is
embedded in the application.

## Development

Requirements:

- macOS with a current Xcode release and an iOS 17 or newer SDK
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

Generate and open the project:

```sh
xcodegen generate
open TypeTypeIOS.xcodeproj
```

Run the complete test suite:

```sh
xcodebuild \
  -project TypeTypeIOS.xcodeproj \
  -scheme TypeTypeIOS \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  test
```

Live backend checks are isolated from the deterministic interface suite:

```sh
xcodebuild \
  -project TypeTypeIOS.xcodeproj \
  -scheme TypeTypeIOSLive \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  test
```

Running either application scheme normally starts the server-connected
application. The `TypeTypeIOSLive` scheme additionally exposes the opt-in live
XCUITest suite. Deterministic interface tests enable their catalog explicitly
with debug-only `--typetype-demo-*` launch arguments.

For a physical device, select the `TypeTypeIOS` target, configure your Apple
development team and bundle identifier, then choose the connected iPhone or
iPad. Signing certificates, provisioning profiles, accounts, instance URLs,
and credentials are not stored in this repository.

## Releases

GitHub Actions validates unit tests and a Release build on pushes to `dev` and
`main`, and on pull requests. Maintainers can publish the version declared by
`MARKETING_VERSION` in `project.yml` by manually running the `iOS` workflow
from `main` with release publication enabled.

Each GitHub release contains an unsigned IPA and its SHA-256 checksum. The IPA
must be signed for the destination device by Xcode or a compatible sideloading
tool. Apple signing certificates, provisioning profiles, and account
credentials are never handled by the public build.

## Project structure

| Path | Contents |
| --- | --- |
| `TypeTypeIOS/App` | Application entry point and root composition |
| `TypeTypeIOS/Core` | Networking, authentication, storage, logging, and configuration |
| `TypeTypeIOS/DesignSystem` | Theme tokens and reusable native components |
| `TypeTypeIOS/Features` | Feature-first screens, models, services, and state |
| `TypeTypeIOS/MockData` | Debug-only deterministic UI-regression catalog |
| `TypeTypeIOS/Resources` | Asset catalogs and bundled playback fixture |
| `TypeTypeIOSTests` | Unit and integration tests |
| `TypeTypeIOSUITests` | Deterministic iPhone and iPad interface regression tests |
| `TypeTypeIOSLiveUITests` | Opt-in end-to-end checks against TypeType-Server |

## TypeType ecosystem

| Repository | Responsibility |
| --- | --- |
| [TypeType](https://github.com/TypeType-Video/TypeType) | Stack, installation, releases, coordination, and issues |
| [TypeType-Frontend](https://github.com/TypeType-Video/TypeType-Frontend) | React browser client |
| [TypeType-Server](https://github.com/TypeType-Video/TypeType-Server) | Kotlin API, extraction, and private user data |
| [TypeType-Player](https://github.com/TypeType-Video/TypeType-Player) | Browser MSE and SABR playback package |
| [TypeType-Android](https://github.com/TypeType-Video/TypeType-Android) | Native Android client |
| [Docs-TypeType](https://github.com/TypeType-Video/Docs-TypeType) | User and self-hosting documentation |

Development changes target `dev`. `main` represents the stable release line.
Bug reports and feature requests belong in the
[central issue tracker](https://github.com/TypeType-Video/TypeType/issues).

## Media and trademarks

The bundled demonstration movie is
[Big Buck Bunny](https://peach.blender.org/), © 2008 Blender Foundation,
licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). The
copy in this repository is encoded for offline application playback.

Third-party names, logos, and trademarks remain the property of their
respective owners. Their inclusion in the interface does not place them under
the Mozilla Public License.

## License

TypeType iOS source code is licensed under the
[Mozilla Public License 2.0](LICENSE).

Copyright © 2026 Priveetee and TypeType contributors.

The MPL-2.0 does not grant rights to third-party media, names, logos, or
trademarks. Those remain subject to their respective licenses and rights.
