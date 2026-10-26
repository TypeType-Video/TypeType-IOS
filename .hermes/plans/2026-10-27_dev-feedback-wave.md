# Dev Feedback Wave — Implementation Plan

> **For Hermes:** Implement task-by-task in later sessions. One task per commit
> (≤390 changed lines). User rebuilds on their Mac after each task; never batch
> risky tasks into one commit.

**Goal:** Work through the developer's 15-point feedback list on TypeType-IOS,
preparing and landing each item as its own small, revertible commit.

**Architecture context:** `dev` already carries beta's in-house player
(TypeTypePlayerKit), the perf wave, and the iOS-Settings shell. Several list
items are ALREADY SOLVED ON BETA as commits we never ported — the plan ports
those first instead of writing new code. Anything android-flavoured on beta
gets re-shaped to iOS style per the user's decision to drop Android parity.

**Validation:** no builds on this machine. After each task the user runs
`git pull --ff-only`, rebuilds in Xcode, and reports. UI-test identifiers
(`live.*`) must survive edits.

---

## Already done — no work needed

| Item from the list | Status |
|---|---|
| Toast for favorite/watch-later | Done: Liquid Glass card with checkmark, centre screen, auto-fade + swipe (`LiveVideoQuickActionsModifier.swift`) |
| 4× playback speed | Done: `playbackRates` in `LivePlayerOptionsSheet+Sections.swift` already lists 4× (verify the in-house engine honours it during task 2.3) |
| Lazy loading home feed | Home feed uses incremental triggers; only **search** still has a Load-more button (task 4.3) |

---

## Phase 1 — Media loading: thumbnails + skeletons (biggest visible win)

Beta already built all of this; we port it and re-skin to iOS/DemoTheme.

### Task 1.1 — Shared image pipeline (cache, downsampling, retries)
- Source commit on beta: `871623e feat: shared image pipeline with cache, downsampling and retries`
- Port `TypeTypeImagePipeline` (adjust name to `LiveImagePipeline`) into
  `TypeTypeIOS/Core/Networking/`.
- Rewire `TypeTypeIOS/Features/Home/Views/LiveRemoteImage.swift` to fetch
  through the pipeline instead of bare `AsyncImage` (it currently does zero
  retries and no cache — the "LOAD THE THUMBNAIL BRO" complaint).
- Keep `LiveImageURLResolver.resolve()` as the URL front-end.
- Acceptance: thumbnails appear reliably, repeated scrolls hit cache, a failed
  load retries (2 attempts, back-off) before showing the placeholder.

### Task 1.2 — Base skeleton component
- Port beta `11b8e8d feat: skeleton layouts instead of loading spinners`.
- New file `TypeTypeIOS/DesignSystem/Components/LiveSkeleton.swift`: rounded
  rect + capsule primitives, theme-aware (`DemoTheme.groupedSurface`),
  gentle opacity pulse.
- Replace the `ProgressView("Loading …")` states in: Home, Subscriptions,
  History, Playlists, Notifications (the screens with list/rows).

### Task 1.3 — Skeletons on the remaining pages
- Port beta `2cfcb38` (lazy comments, video poster while loading) and
  `4fe7363` (remaining secondary pages), re-skinned from beta tokens to
  `DemoTheme` statics.
- Acceptance: no screen shows a bare spinner during first load.

### Task 1.4 (optional, same wave) — DeArrow thumbnail fix + LIVE badge
- Port `34a04e5` (DeArrow thumbnails keep their query instead of 404ing) and
  `736bca8` (LIVE badge + watching count).

**Files touched in phase 1:** `Core/Networking/` (new pipeline),
`Features/Home/Views/LiveRemoteImage.swift`, one new `LiveSkeleton.swift`,
the screen views listed above, `Features/Home/Views/LiveVideoCard.swift`.
**Risk:** low-medium (image pipeline is self-contained; skeletons are cosmetic).

---

## Phase 2 — Player feel

### Task 2.1 — Auto-PiP sensitivity
- File: `TypeTypeIOS/Features/Watch/Views/LivePlayerView+Gestures.swift`
  (`evaluateAutoPictureInPicture`).
- Current trigger: fires whenever `frame.maxY < frame.height * 0.3` while
  armed. Reading comments near the top re-triggers instantly.
- Change: require the surface to be clearly off-screen
  (`frame.maxY < 0` i.e. fully scrolled out), add a re-arm cooldown of ~1.5 s
  after restore, and never start PiP while a scroll gesture is still settling.
- Acceptance: scrolling comments does NOT drop into PiP unless the player is
  fully off-screen; scrolling back still restores inline.

### Task 2.2 — Long-press speed ramp (Android-style)
- Files: `LivePlayerView+Gestures.swift` (`setLongPressBoost` exists),
  `LivePlayerController` (rate), `LiveNativePlayerControls` (rate display).
- Behaviour: hold anywhere on the video → 2×; while held, drag up → ramp
  2.5/3/3.5/4×; drag down → back toward 1×; release → restore previous rate.
- Rate changes must flow through the existing `setPlaybackRate` path so the
  options sheet and the engine stay in sync.

### Task 2.3 — Chapter controls
- Assets exist: `LivePlayerChaptersView.swift` (74 lines),
  `LivePlaybackChapterNavigator.swift`, chapters arrive in
  `LivePlaybackStream.chapters`.
- Wire: add "Chapters" row in `LivePlayerOptionsSheet` listing chapters with
  timestamps; tapping seeks (`controller.seek`). Inline card row above the
  description (like beta `d9c0eff`, iOS-skinned) if the options sheet alone
  feels hidden — decide after first build.
- Verify 4× rate works on the in-house engine while in there.

### Task 2.4 — In-house PiP return/restore (open bug from earlier session)
- Symptom: no switch-back, random pauses. Instrumented logs exist
  (`pip driver:` marks). Diagnosis session against the user's log before
  code changes; likely fix inside `LivePictureInPictureDriver` state machine.

**Risk:** medium (gestures touch scroll interplay — remember the
DragGesture(minimumDistance:0) lesson; boost gesture must stay scoped to the
video surface and use `isPressed`/long-press, not zero-distance drags).

---

## Phase 3 — Watch page layout (title, pill, description)

### Task 3.1 — Remove the channel pill under the title
- File: `TypeTypeIOS/Features/Home/Views/LiveVideoMetadataHeader.swift`.
- The channel avatar+name pill at the bottom edge of the title block goes
  away; the channel row (avatar, name, subscribe) above the actions row
  remains the single channel affordance.

### Task 3.2 — Collapsible description tile
- Files: `LiveVideoMetadataContentView.swift` (the `LiveVideoDescriptionCard`
  call), new `LiveVideoDescriptionTile.swift`.
- New behaviour: no description text visible by default. A slim tile under
  the metadata shows the word "Description" + a chevron (`chevron.down` mini
  arrow); tapping expands the full description in place, tapping again
  collapses. Keep the like-count display from the current card.
- Acceptance: the watch page reads title → channel → actions without a wall
  of text; expansion is one tap, no page push.

**Risk:** low (contained UI swap; keep accessibility identifiers).

---

## Phase 4 — Search overhaul

Files: `Features/Search/Views/LiveSearchView.swift`, `LiveSearchView+Content.swift`,
`LiveSearchViewModel`, `Features/Search/Views/LiveSearchHistoryView.swift`.

### Task 4.1 — Service chooser + no trending
- Add a service chip row at the top of search (YouTube / Bilibili / NicoNico),
  bound to `serviceSelection` like the home toolbar does.
- Remove the trending/shelf content from the search screen — search is search.

### Task 4.2 — Delete confirmation modal
- Wherever search-history rows offer delete: route through a
  `confirmationDialog` (pattern exists in History's clear dialog).

### Task 4.3 — Infinite scroll
- Replace the "Load more" button (`LiveSearchView+Content.swift` ~line 110)
  with `DemoIncrementalLoadingTrigger` at the bottom of results (same pattern
  as notifications/history).

### Task 4.4 — Bar layout
- Search field pinned at top of the search screen, with a back/close button
  (no decorative album-artwork button). Keep the search-tab entry point.

**Risk:** medium (search view model changes: service-scoped queries).

---

## Phase 5 — Channel page cleanup

File: `Features/Search/Views/LiveChannelView+Content.swift` + channel header.

- Reduce header to: compact banner (or banner as a thin strip behind the
  avatar), avatar + name + one-line subscriber count, subscribe pill.
- Remove the oversized in-page search bar (search belongs to the search tab).
- Remove stacked info rows; keep tabs (Videos/Playlists/About) beneath.
- Beta references for behaviour (`98dbf42 one-line subscribe pill`) but built
  iOS-style, not ported verbatim.

**Risk:** medium (layout work; verify paginated channel videos still load).

---

## Phase 6 — Appearance settings

Files: `Features/Settings/Views/LiveSettingsAppearanceView*`.

### Task 6.1 — Pep: preview tiles
- Adapt beta `9b680fe` to iOS: horizontal row of live preview tiles (mini
  feed mock-up in each theme's real colours) + accent colour dots, native
  iOS controls beneath. Replaces flat list rows.

### Task 6.2 — Manga personality (needs user decision)
- If removing: delete manga personality + its options from
  `LiveSettingsAppearanceView` and `LiveAppPreferences` (keep decode
  tolerance so old stored values don't crash), drop the tokens from
  `DemoTheme`.
- If keeping-but-hidden: move behind "Advanced" disclosure.

---

## Phase 7 — Share links

Files: `Features/Watch/Support/LiveShareURLBuilder.swift`,
`LiveVideoUtilityActionsView.swift`.

- The builder already produces instance URLs; the complaint is that shared
  text shows the raw YouTube URL somewhere. Task: audit every share path to
  default to the TypeType instance URL, and add a small
  `confirmationDialog`/"share as" choice (TypeType link / Original link)
  before the system share sheet. Default = TypeType link.

**Risk:** low.

---

## Phase 8 — Push notification budget

Files: `Features/Notifications/Views/LiveNotificationSettingsView.swift`,
`ViewModels/LiveNotificationSettingsViewModel.swift`, push service.

- Add "Enable all" / "Disable all" buttons in the section header.
- Budget guard: the instance caps ~120 queries/user. Count enabled
  subscriptions (each enabled feed = polling queries) and show remaining
  budget; block enabling beyond the cap with an explanatory toast instead of
  letting the server 429.
- Needs one recon step first: find where subscription enable state lives
  (`subscriptionsService`) and whether the instance reports a limit.

**Risk:** medium (server contract unknown until recon).

---

## Suggested order

Phase 1 → 2.1 → 3 → 4 → 2.2 → 2.3 → 5 → 6 → 7 → 8 → 2.4 (PiP bug last,
needs the user's log). Each phase = 1–3 commits, each ≤390 lines.

## Open questions (asked via clarify)

1. Manga personality: remove entirely or hide?
2. Extra action buttons row (user unsure): do it or skip?
3. Share dialog: default choice?
4. Skeleton style: pulsing shimmer or static blocks?
5. Auto-PiP: keep with a much bigger threshold, or remove the feature
   (minimize stays manual)?
