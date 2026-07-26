<div align="center">
  <img src="https://raw.githubusercontent.com/TypeType-Video/TypeType/main/assets/banner.svg" alt="TypeType" width="100%">
  <h1>TypeType-IOS</h1>
  <p>Native SwiftUI client for TypeType.</p>
</div>

<div align="center">

[![Platform](https://img.shields.io/badge/platform-iOS-000000)](https://developer.apple.com/ios/)
[![Language](https://img.shields.io/badge/language-Swift-f05138)](https://www.swift.org)
[![Project](https://img.shields.io/badge/project-XcodeGen-147efb)](https://github.com/yonaskolb/XcodeGen)
[![License](https://img.shields.io/badge/license-MPL--2.0-orange.svg)](LICENSE)

</div>

TypeType-IOS is the native SwiftUI interface prototype for TypeType, a
self-hosted, privacy-respecting video platform. It targets iPhone and iPad on
iOS 17 or later.

The current application is fully interactive and runs entirely on deterministic
mock data. It does not require a backend, an account, or a configured server.

## What this is

A SwiftUI application with a feature-first architecture for browsing,
searching, watching, and managing representative TypeType data on iPhone and
iPad.

The project uses XcodeGen to generate the Xcode project from `project.yml`.

## What this is not

- Not a production backend client yet.
- Not a standalone YouTube client.
- Not a WebView wrapper around the TypeType web app.
- Not the backend source tree or Android client.
- Not affiliated with YouTube, Piped, Invidious, NewPipe, or any upstream video platform.

## Current scope

- Local sign-in, registration, password reset, and OIDC presentation flows.
- Home, search, subscriptions, history, playlists, profile, and administration.
- Native AVKit playback with audible device media, full-screen controls,
  Picture in Picture, mini-player, audio-only presentation, queue, captions,
  SponsorBlock controls, chapters, comments, and related videos.
- Local mutations for favorites, watch later, playlists, downloads, settings,
  moderation, and appearance.
- Public TypeType, PipePipe, YouTube, BiliBili, and NicoNico visual assets.
- Bundled Big Buck Bunny media for repeatable playback demonstrations.

## Stack

| Role | Tool |
|---|---|
| Language | Swift 5.10 |
| Platform | iOS 17+ |
| UI | SwiftUI |
| Playback | AVKit |
| Data | In-memory mock stores |
| Project generation | XcodeGen |

## Project structure

| Path | Purpose |
|---|---|
| `TypeTypeIOS/App` | App entry, launch routing, and root composition |
| `TypeTypeIOS/DesignSystem` | Theme tokens and reusable UI primitives |
| `TypeTypeIOS/Features` | Feature-first screens and feature-local models |
| `TypeTypeIOS/MockData` | Shared deterministic state and local mutations |
| `TypeTypeIOS/Resources` | Asset catalogs and bundled demonstration media |
| `TypeTypeIOSTests` | Unit tests mirroring application domains |
| `TypeTypeIOSUITests` | End-to-end UI tests grouped by feature |

## Development

Requirements:

- macOS with a current Xcode release and an iOS 17 or newer SDK.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen).

Generate the Xcode project:

```bash
xcodegen generate
open TypeTypeIOS.xcodeproj
```

To run on an iPhone or iPad, select the `TypeTypeIOS` target in Xcode, choose
your Apple development team and a unique bundle identifier, select the
connected device, then press Run. The repository does not contain signing
certificates, provisioning profiles, or Apple account credentials.

Run the full local test suite from macOS:

```bash
xcodebuild \
  -project TypeTypeIOS.xcodeproj \
  -scheme TypeTypeIOS \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  test
```

The physical-device demo movie contains H.264 video and AAC audio. Automated
simulator runs use a silent copy of the same movie for deterministic playback
tests.

## Related projects

- [TypeType](https://github.com/TypeType-Video/TypeType) is the deployment stack.
- [TypeType-Frontend](https://github.com/TypeType-Video/TypeType-Frontend) is
  the browser client.
- [TypeType-Server](https://github.com/TypeType-Video/TypeType-Server) is the
  Kotlin API backend.
- [TypeType-Android](https://github.com/TypeType-Video/TypeType-Android) is the
  native Android client.

## Media and trademarks

The bundled demonstration movie is
[Big Buck Bunny](https://peach.blender.org/), © 2008 Blender Foundation,
licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). The
copy in this repository is encoded for offline application playback.

Third-party names, logos, and trademarks remain the property of their
respective owners. Their inclusion in the mock interface does not place them
under the Mozilla Public License.

## License

TypeType-IOS source code is licensed under the
[Mozilla Public License 2.0](LICENSE).

Copyright © 2026 Priveetee and TypeType contributors.

The MPL-2.0 does not grant rights to third-party media, names, logos, or
trademarks. Those remain subject to their respective licenses and rights.
