# Player cheat sheet

How a video goes from a tap to pixels, and where each piece lives
(`TypeTypeIOS/Features/Watch/`).

## The pipeline

```
tap → playbackCoordinator.open(video)                 Playback/LivePlaybackCoordinator.swift
    → LivePlaybackService.stream(for:)                Services/LivePlaybackService.swift
        (metadata + stream resolution, 10 min TTL cache)
    → LivePlayerController (owns one AVPlayer)        Playback/LivePlayerController.swift
    → LivePlayerLayerView (hosts AVPlayerViewController,
      installs the PiP/danmaku content layer)         Views/LivePlayerLayerView.swift
    → presented as fullScreenCover (the ONE player page)
```

## Why a local HTTP server is in the middle

YouTube VOD is SABR (a browser streaming protocol). TypeType-Server transmuxes
it to standard HLS, and the app plays it through `LivePlaybackHTTPServer`
(Network.framework, loopback): AVPlayer points at `localURL(...)` addresses,
the server serves the playlist and segments, attaches the bearer token to
upstream fetches, and stitches SABR windows into media playlists.

- `LiveSABRPlaybackSession` (+`Merge`, `Position`, `Recovery`, `Window`) —
  the server-side SABR session lifecycle (create/seek/prefetch/position).
- `LiveSABRPlaylistBuilder` — builds the HLS playlists AVPlayer consumes.
- `LivePlaybackHTTPServer+Provider` / `+ProgressiveProvider` — upstream
  proxying for provider streams (separate video/audio HLS).

## PiP and the mini player

- Each `LivePlayerController` owns exactly one `LivePictureInPictureDriver`.
  Starting a new video calls `bringInline()` on the old driver first — two
  live drivers stack two PiP scenes (symptoms: "video opens twice",
  `InvalidScene` logs).
- The PiP content layer must live in the visible player's layer tree
  (inserted into `playerController.view.layer`, kept sized). A detached
  `AVPlayerLayer` renders nothing and `isEngaged` sticks.
- `bringInline()` marks the stop as restore, so `onClose` (playback end) does
  not fire from it; only a user closing the PiP window ends playback.
- Auto-PiP on scroll-away is edge-triggered with a re-arm on visibility.
  Auto-started PiP restores inline on scroll-back; manual mini players stay.
- The in-app card (`LiveMiniPlayerView`) is only the fallback when system PiP
  is unavailable (`showsMiniPlayer` excludes engaged PiP).

## Queue, autoplay, sleep timer

`LivePlaybackCoordinator` (+`Queue`, `+SleepTimer`, `+Lifecycle`,
`+Persistence`) owns: the queue snapshot, autoplay countdown (policy in
`DemoAutoplayPolicy`), sleep timer, and session restore. Prewarm: the next
queue video is warmed at playback start, and `LiveVideoCard.onPrewarm` warms
metadata on touch-down.

## Gestures

`PlayerDoubleTapSeek` (double-tap seek), `PlayerSwipeAdjustment`
(brightness/volume/seek swipes), `MiniPlayerDragAction` (drag + snap for the
fallback card).

## Pitfalls that cost real debugging time

- `AVPictureInPictureController` lives in **AVKit**; `init?(playerLayer:)` is
  failable — guard-unwrap.
- `Glass` (iOS 26) has only `.regular` and `.clear` — no `.thin`.
- The danmaku overlay (`LivePlayerLayerCoordinator.install`) must use soft
  pins (priority 999); hard constraints fight AVKit's controls layout and the
  controls go invisible.
- `onChange(of:)` wants the two-parameter closure form.
- Never reintroduce per-list player pushes — one player path only.
