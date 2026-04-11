# TypeType iOS

Native iOS client for TypeType, built with SwiftUI and a feature-first architecture.

## Project Structure

- `TypeTypeIOS/App` app entry, root routing, dependency container
- `TypeTypeIOS/Core` networking, auth, storage, logging, config
- `TypeTypeIOS/DesignSystem` theme tokens and reusable styles
- `TypeTypeIOS/Features` feature modules
- `TypeTypeIOS/Features/ServerSetup` multi-server onboarding
- `TypeTypeIOS/Features/Auth` login/register/refresh scaffolding
- `TypeTypeIOS/Features/Main` app tabs placeholders
- `TypeTypeIOS/Features/Search` search flow
- `TypeTypeIOS/Features/Watch` stream detail screen
- `TypeTypeIOS/Features/Admin` admin placeholder screen

## Generate Xcode Project

This scaffold includes an `xcodegen` specification.

```bash
xcodegen generate
open TypeTypeIOS.xcodeproj
```

## Server Configuration

On first launch, the app asks the user for the server URL and stores it locally.

No default server URL is bundled in source.

If the entered URL has no path, the app normalizes it to `/api`.

## Current Scope

- Multi-server store and active server selection
- Server create/edit/delete flows with connectivity probe
- Root state machine: booting -> server setup -> auth -> main
- JWT login/register/refresh + startup session restore
- Per-server session snapshots + Keychain-backed access tokens
- Home tab loads trending feed from server (`/trending?service=0`)
- Search tab with paginated server search (`/search`)
- Watch screen backed by stream details endpoint (`/streams`)
- Library tab with history and playlists views
- Settings tab can switch server and sign out
- Admin tab lists users with role/suspension/reset-token actions
