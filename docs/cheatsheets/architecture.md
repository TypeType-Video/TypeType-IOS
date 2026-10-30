# Architecture cheat sheet

One page over the TypeType-IOS app. Detail lives in the code; this is the map.

## Startup and app states

`TypeTypeLiveAppView` is the root. `RootCoordinator` drives exactly one state
(`RootState`):

```
booting → serverSetup → authentication → authenticated
```

- `booting`: `LiveLaunchView` while `bootstrap()` restores instance + session.
- `serverSetup`: `ServerSetupView` — pick/add a TypeType instance.
- `authentication`: `LiveAuthView` — login (guest if the instance allows it).
- `authenticated`: `LiveAuthenticatedAppView` — the tabbed app. Re-keyed by
  `coordinator.identityScopeID` so a new identity tears the shell down cleanly.

Extensions of the coordinator keep concerns apart:
`RootCoordinator+Authentication`, `+Session`, `+IncomingLinks`.

## Dependency injection

`AppDependencies` is a struct of protocol-typed services (`AuthServiceProtocol`,
`HomeFeedServiceProtocol`, `LivePlaybackService`, …). `AppDependencies.live()`
(in `AppDependencies+Live.swift`) wires the real stack once; previews and tests
build their own struct with mocks. Views never construct services — they get
dependencies passed in or from `coordinator.dependencies`.

## Demo* vs Live*

`Demo*` types are the offline mock screens (mock session, local fake data).
`Live*` types are the real API-backed app. When reading code, check the prefix
first — a `Demo` screen tells you nothing about production behaviour.

## Opening videos: exactly one path

`playbackCoordinator.open(video)` is the only entry into playback. The player
is presented as `presentsExpandedPlayback` fullScreenCover in
`LiveAuthenticatedAppView+Content.swift`. List screens (Home, Subscriptions,
History, Search, Channels, Playlists, Notifications, Library, Podcasts) all
route through `open()` — there are no per-list `navigationDestination` pushes
into a player page (that used to open every video twice).

Incoming links (`RootCoordinator+IncomingLinks`): videos go to `open()`,
channels/playlists land on `LiveIncomingMediaLinkView` for navigation.

## Storage

- `ServerStore` — configured instances (`ServerProfile`).
- `SessionStore` — session snapshot per instance (persisted login).
- `LiveAppPreferencesStore` — local UI preferences (appearance, player
  gestures, danmaku, …), `Codable` with per-field tolerant decode
  (`LiveAppPreferences`).

## Where things live

```
App/            root view, coordinators, DI, routing
Core/           networking, models, storage, config, logging, security
DesignSystem/   theme engine + shared components
Features/       one folder per screen family (Watch = the player world)
MockData/       demo content
```
