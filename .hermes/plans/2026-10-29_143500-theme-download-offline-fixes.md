# Theme, Download Sheet & Offline Playback Fix Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Fix the eight reported defects: action-button colouring, the unthemed strip at the bottom of the video view, every section header band, the un-dismissable download sheet, inconsistent theme application, missing offline channel avatar, non-working offline controls, and no minimize-swipe on downloaded videos.

**Architecture:** Three work packages. WP-A rebuilds the theming foundation (header slots + page backgrounds + button palette) with an investigation-first step, because three previous header fixes failed on guesses. WP-B is the download sheet's dismissal/state rules. WP-C completes the offline playback experience (image caching, controls, minimize) on the shared player.

**Tech Stack:** SwiftUI (iOS 17 target, iOS 26 Liquid Glass with `#available` guards), UIKit appearance proxies, xcodegen project.

**Context / facts from the screenshots (2026-10-29 14:27–14:29):**
- Settings hub: page is theme-coloured (cream), cards render, but **every section caption sits on a white rounded band** (General / Display and playback / Content / Data and privacy).
- Appearance page: page background is **system grey** while the hub is cream → same app, two different page colours = theme application is inconsistent across screens.
- Download sheet: "Saving on this device" state cannot be swiped away (`interactiveDismissDisabled` while working).
- The video view has a **bottom strip** where the theme never applies (home-indicator / tab band).
- Downloaded video pages: no channel avatar, dead controls, no swipe-to-minimize.

---

## WP-A — Theming foundation (the visual core)

> Root-cause note: the header bands survived colour-role changes, env vs static changes, and cover-on/off changes. The band is a **rounded** shape — our bleed is a plain rect — so the band is drawn by the system header slot, very likely ABOVE our cover. Task 1 must prove the layering before any more colour tweaks.

### Task 1: Prove what draws the header band

**Objective:** Evidence before fixing — determine whether the band is (a) the system chrome drawn above our cover, or (b) our own cover painting the wrong colour.

**Files:**
- Inspect (read-only): `TypeTypeIOS/DesignSystem/Components/Text+LiveSectionHeader.swift`
- Temporary probe (remove in Task 2): same file

**Steps:**
1. In `SlotChromeCover`, give the cover an unmistakable colour for one build: `Color.red`. Also keep the text visible.
2. Build, open Settings → Appearance in light + dark themes.
3. Record which of these the band looks like:
   - **Band is red** → our cover paints, colour resolution is wrong (root cause (b); Task 2 = pick the right role with proof from `DemoTheme`'s role table).
   - **Band is white/grey (not red)** → the system chrome draws above our cover (root cause (a); Task 3 = structural fix, skip colour work).
4. Paste the observation into the task log before continuing.

**Verification:** One screenshot per theme with the probe colour visible or not.

### Task 2 (only if root cause (b)): Fix the cover colour from the role table

**Objective:** The cover paints exactly the colour behind the caption.

**Files:**
- Modify: `TypeTypeIOS/DesignSystem/Theme/DemoTheme.swift` (role definitions: `background`, `pageBackground`, `groupedBackground`, `rowBackground`, `groupedSurface`)
- Modify: `TypeTypeIOS/DesignSystem/Components/Text+LiveSectionHeader.swift`

**Steps:**
1. Dump each role for the active theme (temporary debug view or a log line in `applyUIKitAppearance`) and note which role equals the **page colour behind the list**.
2. Point `SlotChromeBackground` at that role via the **live env palette** (`@Environment(\.demoTheme)`), not a static.
3. Remove the probe colour.
4. Build; check Settings, Player options sheet, Download sheet in TypeType + Cream + AMOLED.

**Verification:** Captions sit directly on the page in all three themes; no band edge visible.

### Task 3 (only if root cause (a) — or as the guaranteed fallback): Captions out of the header slots

**Objective:** No system header chrome exists to fight — captions render as page-level rows.

**Files:**
- Modify: every grouped screen using `header: { Text(...).liveSectionHeader() }`:
  - `TypeTypeIOS/Features/Settings/Views/LiveSettingsView.swift`
  - `TypeTypeIOS/Features/Settings/Views/LiveSettingsPages.swift`
  - `TypeTypeIOS/Features/Settings/Views/LiveSettingsPlaybackSection.swift`
  - `TypeTypeIOS/Features/Settings/Views/LivePrivacyDataView.swift`
  - `TypeTypeIOS/Features/Settings/Views/LiveSettingsCaptionAppearanceView.swift`
  - `TypeTypeIOS/Features/Home/Views/LiveDownloadSheet*.swift`
  - `TypeTypeIOS/Features/Watch/Views/LivePlayerOptionsSheet*.swift`
  - `TypeTypeIOS/Features/Import/Views/LiveImportView*.swift`, `LivePortabilityView.swift`
- Modify: `TypeTypeIOS/DesignSystem/Components/Text+LiveSectionHeader.swift`

**Steps:**
1. Add a small `liveSectionCaption` view modifier that renders a caption as a clear full-width row (`.listRowBackground(Color.clear)`, zero/minimal insets, caption typography unchanged).
2. In one screen first (LiveSettingsView), move each caption from `header: { … }` to a `Text` row placed immediately **before** its `Section`.
3. Build; confirm the band is gone and the caption reads identically.
4. Convert the remaining screens in small commits (2 files per commit).
5. Delete `SlotChromeCover`/`SlotChromeBackground` once nothing uses them (check with a repo-wide grep).

**Verification:** Repo-wide grep shows zero `liveSectionSlotChrome()` callers; screenshots of every converted screen show captions on the page with no band.

### Task 4: Unify page backgrounds across screens

**Objective:** Every themed screen shows the theme's page colour; no screen shows the system grouped grey.

**Files:**
- Modify: `TypeTypeIOS/DesignSystem/Theme/DemoTheme.swift` (`liveGroupedList()`)
- Modify: `TypeTypeIOS/Features/Settings/Views/LiveSettingsPages.swift` (the editing-page wrapper used by Appearance/Player/…)
- Verify-only: `LiveSettingsView.swift`, `LiveDownloadSheet.swift`, `LivePlayerOptionsSheet.swift`

**Steps:**
1. Reproduce first: open Settings (cream) and Appearance (grey) in the same theme; screenshot both — the divergence is the acceptance test.
2. In `liveGroupedList()`, add `.scrollContentBackground(.hidden)` + `.background(<theme page colour>)`. This must NOT flatten the cards (cards live in the cell backgroundView — confirm in Task 5).
3. Ensure `LiveSettingsEditingPage` uses the same modifier chain as `LiveSettingsView`.
4. Build; compare the two screens in TypeType + AMOLED — identical page colour.

**Verification:** Screenshot pair (hub + sub-page) per theme; page colour identical.

### Task 5: Verify card theming survives theme switches

**Objective:** Cards/rows follow the theme immediately on switch (last round's fix is unverified).

**Files:**
- Verify-only: `DemoTheme.swift` (`applyUIKitAppearance`, `refreshLiveBars`)

**Steps:**
1. Settings → Appearance → switch TypeType → Cream → AMOLED without leaving the page.
2. Confirm cards + page recolour each time (the `refreshLiveBars` re-apply from the previous round should handle it).
3. If cards lag: re-apply `UITableViewCell/UICollectionViewCell.appearance().backgroundColor` from the same refresh path and retest.

**Verification:** Three consecutive switches, all three states correct without app restart.

### Task 6: Action buttons — coloured, but lighter

**Objective:** The circles are coloured again (accent-tinted active, themed inactive) and clearly lighter than the "too dark" version.

**Files:**
- Modify: `TypeTypeIOS/Features/Library/Views/LiveVideoLibraryActionsView.swift` (`iconLabel`)
- Reference: `DemoTheme.swift` (`LiveChipButtonStyle` for the capsule buttons)

**Steps:**
1. Git-log the three earlier looks of `iconLabel` (`git log -p -- …/LiveVideoLibraryActionsView.swift | grep -A6 iconLabel`) and restore the **coloured** structure the user approved (accent wash active / themed surface inactive).
2. Make both states lighter: raise transparency of the wash (e.g. active `accent.opacity(0.30)`, inactive `surface.opacity(0.45)`) and keep the glass tint; glyphs stay white on active, primary on inactive.
3. Check in a light theme (Cream) and a dark one (AMOLED) — "lighter than before" is the acceptance in both.
4. If a theme still reads dark: mix the tint toward white 25% (helper `lightened(by:)` on Color) and retest.

**Verification:** Side-by-side feel against the screenshot `upload_44apf_r9.png` era buttons; tap favourite → active tint visible with legible glyph.

### Task 7: Bottom strip of the video view takes the theme

**Objective:** No unthemed strip at the bottom of the video page (home-indicator / tab band).

**Files:**
- Modify: `TypeTypeIOS/Features/Home/Views/LiveVideoMetadataContentView.swift`
- Modify: `TypeTypeIOS/App/LiveAuthenticatedAppView+Content.swift` (expanded cover)
- Modify: `TypeTypeIOS/Features/Downloads/Playback/LiveOfflinePlaybackView.swift`

**Steps:**
1. Reproduce: open any video, scroll to the very bottom; screenshot the 100pt strip (the user's `upload_nywed_y5.jpg` region).
2. Identify the unpainted layer (likely the safe-area band under the scroll content in the expanded cover, or the mini-player band).
3. Paint it with the same `DemoThemeBackground()` chain the page uses (already added to the two hosts — extend to the missing layer).
4. Verify in light + dark themes and with the mini player visible.

**Verification:** Screenshot of the bottom strip matches the page colour in both themes.

---

## WP-B — Download sheet

### Task 8: Make the sheet swipe-dismissable

**Objective:** The sheet can always be swiped away; it never traps the user.

**Files:**
- Modify: `TypeTypeIOS/Features/Home/Views/LiveDownloadSheet.swift`

**Steps:**
1. Read `LiveDownloadViewModel.isWorking` — confirm "Saving on this device" sets it true (this is why `interactiveDismissDisabled` blocks the swipe).
2. Change the rule: disable interactive dismissal only while a **server transfer is cancellable** (states: creating/tracking with `!isFinishing`); once `isFinishing` or `.done`, allow dismissal.
3. Add `.presentationDragIndicator(.visible)` so the affordance is obvious.
4. Build; start a download, swipe the sheet away mid-transfer (should refuse), then during "Saving on this device" swipe it away (should work).

**Verification:** The swipe test matrix above; closing mid-save leaves the download row progressing on the Downloads screen.

---

## WP-C — Offline playback completeness

### Task 9: Cache the channel avatar for offline pages

**Objective:** Downloaded video pages show the channel profile picture without network.

**Files:**
- Modify: `TypeTypeIOS/Features/Downloads/Models/LiveManagedDownload.swift` (`LiveOfflineVideoMetadata` — add `localAvatarFileName: String?`)
- Modify: `TypeTypeIOS/Features/Downloads/ViewModels/LiveDownloadCenter+Actions.swift` (at `start(...)`)
- Modify: `TypeTypeIOS/Features/Downloads/Playback/LiveOfflinePlaybackItem.swift` (map the local file into the watch metadata)
- Reference: `TypeTypeIOS/Features/Home/Views/LiveRemoteImage.swift` (offline/file URL support)

**Steps:**
1. In `LiveDownloadCenter.start`, after the record is created, download `video.uploaderAvatarURL` (small image) into the artifacts directory with `URLSession.shared.data` (respect the download session timeout rules from WP-B's learnings) and store the file name in the record metadata.
2. In `LiveOfflinePlaybackItem.watchVideo`, when `localAvatarFileName` exists, pass a **file URL** as `uploaderAvatarURL`; make sure `LiveRemoteImage` renders `file://` URLs (it currently expects remote URLs — add a local-file branch if missing).
3. Old records without the cache fall back to the empty avatar (unchanged behaviour).
4. Test: download a video, enable Airplane Mode, open the download → avatar visible.

**Verification:** Airplane-Mode screenshot of the offline page with the avatar rendered.

### Task 10: Make the offline player controls work

**Objective:** Tapping the stage shows the HUD; play/pause, slider, seek gestures all work on downloaded videos.

**Files:**
- Modify: `TypeTypeIOS/Features/Watch/Views/LivePlayerView.swift` (control visibility condition)
- Modify: `TypeTypeIOS/Features/Watch/Views/LivePlayerView+Surface.swift` (gesture installation on the offline layer)
- Reference: `TypeTypeIOS/Features/Watch/Components/LivePlayerLayerCoordinator.swift`, `LivePlayerController+Loading.swift` (`installPlayerItem`, `observe`)

**Steps:**
1. Reproduce: open a downloaded video; log which pieces of the chain are alive (`nativePlayback == nil`, `state`, `position`) with one temporary `AppLogger.playback` line in `LiveNativePlayerControls.body`.
2. The HUD visibility gate is `controller.nativePlayback != nil || controller.isOfflineContent` — confirm the HUD renders for offline (it was switched last round).
3. Check the **interaction** chain: `LivePlayerLayerView`'s tap/drag recognizers are installed via `LivePlayerLayerCoordinator.install*Gesture` on the AVPlayerViewController's view — verify they install for the offline surface too (they were attached in `makeUIViewController`; verify `updateUIView` doesn't drop them).
4. Check the slider/seek path: `controller.seek` + `observe(item:)` position updates must reflect the AVPlayer of the offline item (they go through `controller.player` — the same player `installPlayerItem` populated; verify `observe` is attached for local assets).
5. Fix whichever link is dead; then verify play/pause, slider scrub, double-tap ±10s, hold-for-speed on a downloaded video.

**Verification:** Each control exercised once on a downloaded video; log line shows `state`/`position` changing.

### Task 11: Swipe-to-minimize on downloaded videos

**Objective:** Pulling down the offline video page minimizes it like the online player.

**Files:**
- Modify: `TypeTypeIOS/Features/Downloads/Playback/LiveOfflinePlaybackView.swift`
- Reference: `TypeTypeIOS/App/LiveAuthenticatedAppView+Content.swift` (`minimizePullDown`), `LiveVideoMetadataContentView` (page gestures)

**Steps:**
1. Compare how the expanded online player installs `minimizePullDown` (`.simultaneousGesture(minimizePullDown)` on `expandedPlayback`) with the offline cover, which currently only has a Close button.
2. Add the same pull-down gesture to the offline cover's content, mapped to `dismiss()` (the offline page is a cover, not the coordinator's expanded state — dismissing returns to Downloads; do NOT call `playbackCoordinator.minimize()`, which would show the mini player for a controller the coordinator doesn't own).
3. Gate it like the online one (only from the top region, only when the player surface is visible) to avoid fighting vertical scrolling.
4. Test: pull down from the video area → page closes, audio keeps playing in the mini card? (Decide: for offline, closing the page should stop or keep playing — default: keep playing and let the mini player show only if the coordinator owns the controller; otherwise stop playback on close. Record the decision in the code comment.)

**Verification:** Swipe-down closes the offline page without fighting the comments scroll.

---

## Sequencing & risk

1. **WP-A first** (Task 1 → 2/3 → 4 → 5 → 6 → 7): theming is the user's top complaint and Task 1's evidence determines Task 2 vs 3. Do not start Task 2 or 3 before Task 1's observation is recorded.
2. **WP-B** (Task 8) is independent and quick; can ship early for momentum.
3. **WP-C** (Tasks 9–11) is independent of theming; safest last.

**Risks / open questions:**
- Header chrome z-order (Task 1) may be un-fixable by covering — Task 3 is the guaranteed path and the fallback if Task 2 fails.
- Task 4's `.scrollContentBackground(.hidden)` previously interacted badly with card rendering (the "flat" bug) — that was caused by a blanked cell backgroundView; keep `applyUIKitAppearance`'s `backgroundView` handling in mind while testing.
- Task 11's behaviour decision (keep playing vs stop on close) needs a one-line product answer from the user if the default proves wrong.
- iOS 26 vs 17 fallbacks: every glass change must keep its `#available(iOS 26.0, *)` fallback; test at least once on the pre-26 path (simulator) for the buttons (Task 6).

**Tests / validation (project has no unit-test target for UI):**
- Per-task manual checklists above (this repo's convention — the user builds and screenshots).
- After WP-A and WP-C: one screenshot per theme (TypeType light, Cream, AMOLED) of Settings + video page + offline page as the regression pack.
