<div align="center">
  <img src="https://raw.githubusercontent.com/TypeType-Video/TypeType/main/assets/banner.svg" alt="TypeType" width="100%">
  <h1>TypeType-IOS</h1>
  <p>Native SwiftUI client for TypeType.</p>
</div>

<div align="center">

[![Platform](https://img.shields.io/badge/platform-iOS-000000)](https://developer.apple.com/ios/)
[![Language](https://img.shields.io/badge/language-Swift-f05138)](https://www.swift.org)
[![Project](https://img.shields.io/badge/project-XcodeGen-147efb)](https://github.com/yonaskolb/XcodeGen)
[![License](https://img.shields.io/badge/license-not%20declared-lightgrey)](#license)

</div>

TypeType-IOS is the native SwiftUI interface prototype for TypeType, a
self-hosted, privacy-respecting video platform.

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
- Native playback, mini-player, audio-only presentation, queue, captions,
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

Generate the Xcode project:

```bash
xcodegen generate
open TypeTypeIOS.xcodeproj
```

Run the full local test suite from macOS:

```bash
xcodebuild \
  -project TypeTypeIOS.xcodeproj \
  -scheme TypeTypeIOS \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  test
```

## Related projects

- [TypeType](https://github.com/TypeType-Video/TypeType) is the deployment stack.
- [TypeType web](https://github.com/TypeType-Video/TypeType) is the browser client.
- [TypeType-Server](https://github.com/TypeType-Video/TypeType-Server) is the Kotlin API backend.
- [TypeType-Android](https://github.com/TypeType-Video/TypeType-Android) is the native Android client.

## License

No license file is currently present in this repository.
