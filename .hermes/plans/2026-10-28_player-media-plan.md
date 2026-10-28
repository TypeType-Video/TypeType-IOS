# Player & Media Polish — Implementation Plan

> **For Hermes:** Implement task-by-task. One task per commit (≤390 changed
> lines). User rebuilds on their Mac after each task (`git pull`, plus
> `xcodegen generate` when a task adds or deletes files) and tests on the
> phone. UI-test identifiers (`live.*`) must survive edits. No new design
> tokens; `DemoTheme` statics only.

**Goal:** Land the developer's fullscreen PR as the base, then add the
missing media features: progress bars on every thumbnail, SponsorBlock
segments and a chapters button in the player progress bar, Dynamic Island
for audio-only playback, and the 120-request notification budget.

**Architecture context:** PR #3 (`fix/rotation-fullscreen` → `dev`, "Full
screen: follow the phone's turn in one motion") supersedes the previous
fullscreen work: the transparent host and its timers are gone, the watch
page follows the window shape, `LiveNativeFullscreenPresenter` is the only
owner of entering/leaving, and `LiveOrientationLock` pins orientations.
**Merge PR #3 first** — every later task builds on the merged tree; expect
conflicts in `LiveNativeFullscreenView`, `LivePlayerView`,
`LiveVideoMetadataContentView` and `LivePlayerController+Native`.

**Validation:** no builds on this machine. After each task the user runs
`git pull` (+ `xcodegen generate` when files were added/removed), rebuilds
in Xcode, and reports.

---

## Phase 0 — Land PR #3 and reconcile

### Task 0.1 — Merge PR #3 into dev
- DECIDED: this plan merges `fix/rotation-fullscreen` (PR #3) as its first
  executed task, **after the user says go**. Do not start before that.
- Resolve conflicts **in favour of the PR's design** (it deletes the
  transparent host, the `onRotate` hook, the fallback timers and the
  `dismissActive` machinery). Keep `bdef757`'s `fullscreen:` logging only
  where the PR's code still has natural hook points; the PR's own flow
  wins otherwise.
- Acceptance: the app builds; the PR's 9-step device tour passes unchanged.

### Task 0.2 — Re-apply the surviving watch-page wins onto the PR's layout
- The rounded lower corners of the pinned player while the page is scrolled
  (`LivePlayerSizing` in `LivePlayerView.swift`: `UnevenRoundedRectangle`,
  radius 40/24 scrolled, 0/16 at rest, cinema-aware bleed note) — verify it
  still reads correctly against the PR's new player layout; adapt the
  modifier to the PR's sizing path if it moved.
- The metadata collapse / overlay player only if the PR's layout still uses
  them; if the PR supersedes them, drop them without porting.
- Acceptance: watch page at rest = square lower edge; scrolled = rounded;
  no regression to the PR's rotation behaviour.

---

## Phase 1 — Progress bar in every thumbnail

### Task 1.1 — Watch-progress bar on every video thumbnail
- Files: `TypeTypeIOS/Features/Home/Views/LiveVideoCard.swift` (it already
  reads `LiveWatchProgressStore.shared.fraction(forVideoID:)` around line
  85), `TypeTypeIOS/Features/History/Services/LiveWatchProgressStore.swift`.
- Behaviour: a slim bar along the thumbnail's bottom edge, width =
  watched fraction, visible whenever `0 < fraction` (completed videos show
  a full bar). Accent-ish colour: `DemoTheme.accent`, height ~3 pt, no
  corner radius beyond the thumbnail's clip. It rides the thumbnail's
  existing `clipShape` so it never bleeds past rounded corners.
- All cards render through `LiveVideoCard` (feed, search, channel,
  related, queue previews) — one change covers "every thumbnail". Verify
  by scrolling each surface.
- Acceptance: partially watched videos show the bar on every surface;
  unwatched show none; completed show full.

### Task 1.2 — Progress bar on the remaining thumbnail hosts
- Files: `TypeTypeIOS/Features/Watch/Views/LivePlaybackQueueRow.swift`,
  `TypeTypeIOS/Features/History/Views/*` rows if they draw thumbnails
  without `LiveVideoCard`.
- Same bar, same rules. Acceptance: queue and history thumbnails match.

---

## Phase 2 — Progress bar (timeline) upgrades

### Task 2.1 — SponsorBlock segments on the progress bar (mark/skip modes)
- Files: `TypeTypeIOS/Features/Watch/Views/LiveNativePlayerControls.swift`
  (the `timeline` = clock + `Slider` + clock), `TypeTypeIOS/Features/Watch/
  Models/LivePlaybackTimelineModels.swift` (`LivePlaybackSponsorSegment`),
  `TypeTypeIOS/Features/Watch/Playback/LivePlayerController+SponsorBlock.swift`
  (segment list + the active mode), `TypeTypeIOS/Features/Watch/Components/
  LiveSponsorBlockOverlay.swift` (reference only).
- Behaviour: when the user's SponsorBlock action is **mark** or **skip**,
  draw each segment as a thin band over the timeline track at
  `start/duration … end/duration` fractions. DECIDED: **one colour per
  category** — map `LivePlaybackSponsorSegment`'s category to a small
  fixed palette (sponsor orange, selfpromo blue, interaction purple,
  intro/outro green, music red, preview grey; unknown = grey), bands at
  55 % opacity over the track. Hidden when SponsorBlock is off or set to
  fill/other actions. The bands are display-only (no tap targets) — YAGNI.
- Implementation note: the `Slider` track can't carry subviews; lay the
  bands in a `ZStack` UNDER the slider with `allowsHitTesting(false)`, the
  slider's own track made transparent (`.tint(.white)` stays for the thumb).
  Mirror the slider's horizontal insets so band fractions line up.
- Acceptance: with SponsorBlock "mark"/"skip" active, segments show as
  bands aligned with the skips in the video; switching SponsorBlock off
  removes them; the slider still scrubs normally.

### Task 2.2 — Chapters button in the progress bar
- Files: `TypeTypeIOS/Features/Watch/Views/LiveNativePlayerControls.swift`,
  `TypeTypeIOS/Features/Watch/Views/LivePlayerChaptersView.swift` (reuse),
  `TypeTypeIOS/Features/Watch/Support/LivePlaybackChapterNavigator.swift`
  (clock text + chapter lookup).
- Behaviour: a small button at the timeline's trailing edge (system image
  `list.bullet.rectangle`), visible only when `controller.stream?.chapters`
  is non-empty. Tapping opens the chapters list as a **popover dropping
  downward** from the button (the standing dropdown rule), rows = chapter
  title + timestamp; tapping a row seeks (`controller.seek`) and closes.
  `LivePlayerChaptersView` may already render the list — reuse it inside
  the popover instead of building a new row type.
- Acceptance: chapters button appears only on chaptered videos; the
  popover drops down and is fully visible (scrolls if long); tapping a
  chapter seeks there.

---

## Phase 3 — Dynamic Island for audio-only playback

### Task 3.1 — Now-playing widget extension scaffold
- Files: `project.yml` (new target `type: app-extension` /
  `bundle.extension` for a widget, `deploymentTarget: 17.0`), new
  `Extensions/NowPlayingLiveActivity/` with the extension entry point.
- This task ADDS files/targets: the user must run `xcodegen generate`
  after pulling, and the extension must be added to the app's signing
  capabilities on the Mac.
- Acceptance: the empty extension builds and embeds in the app.

### Task 3.2 — Live Activity content (artwork, title, controls)
- Files: `Extensions/NowPlayingLiveActivity/*` (attributes + the Dynamic
  Island compact/expanded content + the lock-screen banner).
- Content: artwork thumbnail, title, a play/pause toggle; expanded state
  adds the channel name and ±10 s skip. Widget bundle registration.
- Acceptance: a started activity renders in the Dynamic Island (simulator
  is fine) with the right content.

### Task 3.3 — Wire the activity to audio-only playback
- Files: `TypeTypeIOS/Features/Watch/Playback/Native/LiveNowPlaying.swift`,
  `TypeTypeIOS/Features/Watch/Playback/LivePlayerController.swift`
  (`audioOnly`, `setAudioOnly`), a small `LiveAudioActivityController`
  (start on audio-only enter, update on play/pause/title/artwork changes,
  end on exit/playback end/app termination).
- Acceptance: toggling audio-only shows/updates the Dynamic Island
  activity; play/pause from the island controls playback; leaving
  audio-only ends the activity. Live video keeps the normal behaviour
  (the system media path — see open question 4).

---

## Phase 4 — Notifications: 120-request budget

### Task 4.1 — Verify the budget guard after the merge
- Files: `TypeTypeIOS/Features/Notifications/ViewModels/
  LiveNotificationSettingsViewModel.swift`, `TypeTypeIOS/Features/
  Notifications/Views/LiveNotificationSettingsView.swift`, `TypeTypeIOS/
  Features/Notifications/Services/LivePushNotificationsService.swift`.
- Already implemented on dev (cap 120 queries/user, remaining-budget
  footer, enable/disable all with budget-aware skipping, per-channel PUTs
  throttled to 200 ms). This task only re-verifies after the PR merge and
  keeps the identifiers (`live.notification-settings.*`).
- Acceptance: enable-all stops at the budget and toasts the skipped count;
  a single enable past the cap is blocked with a toast; no 429s.

### Task 4.2 (optional) — Server-reported budget
- If the instance ever reports a limit, prefer it over the constant
  (`pollingQueryBudget`). No endpoint exists today — leave the constant.

---

## Suggested order

Phase 0 → 1 → 2 → 4 → 3. The Dynamic Island is last: it needs a new
extension target, signing, and the most device-side verification.

## Open questions — DECIDED (28 Oct 2026)

1. Thumbnail progress: every watched video shows the bar; completed videos
   show a full bar. ✓
2. SponsorBlock bands: **colour per category** (see Task 2.1). ✓
3. Chapters button: trailing edge of the timeline. ✓
4. Dynamic Island: full Live Activity with the widget extension. ✓
5. PR #3: the plan merges it as Task 0.1, once the user says go. ✓

## Risks

- Phase 0 conflicts: the PR rewrites the fullscreen architecture the
  previous rounds touched; resolve for the PR's design and re-test the
  rotation tour before starting Phase 1.
- Timeline bands under a `Slider` depend on the track's exact insets;
  verify alignment on both iPhone sizes the user tests with.
- The widget extension changes the Xcode project; the user's `xcodegen`
  step is mandatory from Task 3.1 on.
