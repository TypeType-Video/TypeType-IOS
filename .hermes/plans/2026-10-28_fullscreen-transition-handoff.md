# Fullscreen transition — handoff to dev (28 Oct 2026)

Agent-driven work on the fullscreen experience, 10 commits `8068803..0a517bb` (this file
excluded). The user reports the motion "only gets worse" at HEAD — handing over. All
diagnosis evidence below is from user-supplied screen recordings + `fullscreen:` logs.

## User-verified working (safe to keep)

| Commit | What |
|---|---|
| `bdef757` | `fullscreen:` instrumentation across the whole enter/exit chain (keep it — it diagnosed every round) |
| `ef8bb17` | Stuck-modal fix: deleted the stale geometry-era fullscreen overlay in `LiveVideoMetadataView` (it posed as the modal) — "Better now" |
| `81ff1cf` | Rotation control: `UIDevice.orientationDidChangeNotification` driven — rotate-to-portrait exits (350 ms debounce), rotate-to-landscape enters (edge-triggered, 0.8 s arm), landscape flip, device-matched `preferredInterfaceOrientationForPresentation` — "the groundwork is done" |
| `e8dc32e` | One rotation request per transition + `LiveScreenOrientation.set` idempotency guard + 250 ms persistence debounce on the geometry self-dismiss (verified in log: exactly one `orientation set` per direction, no bounce) |

## The problematic part: transition feel ("too many steps", "not one motion")

| Commit | What | Verdict |
|---|---|---|
| `f200295` | Stage rides the rotation (`LivePlayerSizing` restored), modal demoted to transparent `.overFullScreen` chrome host | "Definitely better" came only after `f0db3bc` |
| `f0db3bc` | Metadata collapses (layoutPriority outermost + explicit `maxHeight: 0`) | **BEST-VERIFIED STATE** — "Definitely better but it's still not one motion" |
| `ed81ad5` | Growth/collapse/chrome ride the system `UIViewControllerTransitionCoordinator` (`viewWillTransition` → `animate(alongsideTransition:)`) | still "too many steps" |
| `5c5384e` | Compile fix (`transitionDuration`, not `duration`) | — |
| `de9089d` | Player becomes a page-level `.overlay` over a placeholder slot — stage grows OVER a still page (no collapse motion) | still not one motion |
| `0a517bb` | Fallback-timer race fix (see below) | user: "it only gets worse" |

**Suggestion:** `f0db3bc` is the state the user liked most. Consider resetting the feel
work to it (`git revert 0a517bb e8dc32e de9089d 5c5384e ed81ad5` — or cherry-pick `e8dc32e`
on top, its single-rotation-request fix is independent and verified) and attack the
"one motion" goal differently.

## Mechanisms established (useful regardless)

- **The hook race (0a517bb's diagnosis):** UIKit starts a requested rotation ~300 ms after
  `requestGeometryUpdate`. A fallback timer shorter than that flips the growth flag first,
  and the late `viewWillTransition` dies on its guard — log showed only
  `rotation hook missed`, growth never rode the rotation. At `0a517bb` the fallback is
  800 ms so the hook should win; NOT yet user-verified.
- **One rotation request per transition:** the `onDisappear` backstop's second
  `requestGeometryUpdate(.portrait)` re-kicked the return rotation ("doesn't stop, keeps
  moving, bounces"). Removed in `e8dc32e`.
- **Geometry self-dismiss** (`wasLandscape` guard) fires on transient portrait layout
  passes when a rotation restarts mid-flight → bounced fullscreen right back out. Now
  needs 250 ms persistence (cancelled on landscape).
- `LiveNativeLayerOwner` (unchanged, pre-existing): one `AVSampleBufferDisplayLayer` shared
  across hosts by surface priority; adopting keeps the carried frame (no blink).
- AVKit-fallback fullscreen goes through `LivePlayerLayerCoordinator+Presentation.swift`
  (separate path; also calls `LiveScreenOrientation.set`).

## Where the state lives

- `LiveNativeFullscreenView.swift` — transparent chrome host + `LiveLandscapeHostingController`
  (orientation authority: `.landscape` hold + `relaxesForExit` at dismissal), `present(for:)`
  re-sequenced: present first (`animated: false`), then request rotation; growth flips the
  `isPresentingFullscreen` flag inside the coordinator block.
- `LivePlayerView.swift` — `LivePlayerSizing` (fill window + `layoutPriority(1)` vs 16:9 card),
  rotation-to-enter observer, chrome hidden while fullscreen.
- `LiveVideoMetadataContentView.swift` — player is a page-level `.overlay(alignment: .top)`
  over a `Color.clear` placeholder slot; toolbar/status bar gated on the flag.
- `LiveScreenOrientation.swift` — request-only rotation helper with idempotency guard.
- Tunables: `growthDuration` (0.32 s), fallback timer (800 ms), sensor debounce (350 ms),
  geometry debounce (250 ms).
