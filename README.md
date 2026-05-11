<div align="center">
  <img src="https://raw.githubusercontent.com/Priveetee/TypeType/main/assets/banner.svg" alt="TypeType" width="100%">
  <h1>TypeType-IOS</h1>
  <p>Native SwiftUI client for TypeType.</p>
</div>

<div align="center">

[![Platform](https://img.shields.io/badge/platform-iOS-000000)](https://developer.apple.com/ios/)
[![Language](https://img.shields.io/badge/language-Swift-f05138)](https://www.swift.org)
[![Project](https://img.shields.io/badge/project-XcodeGen-147efb)](https://github.com/yonaskolb/XcodeGen)
[![License](https://img.shields.io/badge/license-not%20declared-lightgrey)](#license)

</div>

TypeType-IOS is the native iOS client for TypeType, a self-hosted, privacy-respecting video platform.

The app talks to TypeType-Server over HTTP only. It does not bundle extraction logic or a default server URL.

## What this is

A SwiftUI application with a feature-first architecture for browsing, searching, watching, and managing TypeType user data from iPhone or iPad.

The project uses XcodeGen to generate the Xcode project from `project.yml`.

## What this is not

- Not a standalone YouTube client.
- Not a WebView wrapper around the TypeType web app.
- Not the backend source tree or Android client.
- Not affiliated with YouTube, Piped, Invidious, NewPipe, or any upstream video platform.

## Current scope

- Multi-server setup and active server selection.
- Server create, edit, delete, and connectivity probe flows.
- Boot, server setup, auth, and main app state routing.
- Login, register, refresh, startup session restore, and Keychain-backed access tokens.
- Trending, search, stream details, history, playlists, settings, and admin user screens.
- Watch actions for favorites, watch later, and subscriptions.

## Stack

| Role | Tool |
|---|---|
| Language | Swift 5.10 |
| Platform | iOS 17+ |
| UI | SwiftUI |
| Concurrency | async/await |
| Networking | URLSession |
| Auth storage | Keychain |
| Local storage | UserDefaults |
| Logging | os.Logger |
| Project generation | XcodeGen |
| CI | GitHub Actions on macOS |

## Project structure

| Path | Purpose |
|---|---|
| `TypeTypeIOS/App` | App entry, root routing, dependency container |
| `TypeTypeIOS/Core` | Networking, auth, storage, logging, config |
| `TypeTypeIOS/DesignSystem` | Theme tokens and reusable UI primitives |
| `TypeTypeIOS/Features` | Feature modules, views, view models, models, and services |
| `TypeTypeIOSTests` | Unit tests |

## Server configuration

On first launch, the app asks for the server URL and stores it locally.

If the entered URL has no path, the app normalizes it to `/api`.

## Development

Generate the Xcode project:

```bash
xcodegen generate
open TypeTypeIOS.xcodeproj
```

Run the CI-equivalent checks from macOS:

```bash
xcodebuild \
  -project TypeTypeIOS.xcodeproj \
  -scheme TypeTypeIOS \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Related projects

- [TypeType](https://github.com/Priveetee/TypeType) is the deployment stack.
- [TypeType web](https://github.com/Priveetee/TypeType) is the browser client.
- [TypeType-Server](https://github.com/Priveetee/TypeType-Server) is the Kotlin API backend.
- [TypeType-Android](https://github.com/Priveetee/TypeType-Android) is the native Android client.

## License

No license file is currently present in this repository.
