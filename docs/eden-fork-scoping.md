# Scoping: contributing cloud-sync-friendly saves to the Eden emulator

*Researched 2026-07-21. Sources linked at bottom.*

> ## ⚠️ OUTCOME (added same day, after reading the actual source): fork not needed
>
> 1. **Eden already shipped the scoped feature.** Upstream PR
>    [#3154 — "Implement custom save path setting and migration"](https://git.eden-emu.dev/eden-emu/eden/pulls/3154)
>    added a user-facing **Settings → "Save Data Directory"** (verified in
>    `SettingsFragmentPresenter.kt:1310` / `SettingsFragment.kt` in the current
>    mirror, localized into ~12 languages) with a directory picker,
>    all-files-access permission, and built-in save migration. Issue #251 is
>    answered by shipped code. Setting the save dir to a public folder (e.g.
>    `/storage/emulated/0/EdenSaves`) makes saves land in
>    `EdenSaves/user/save` — externally syncable, **no root, no fork**.
>    The `eden` profile in `profiles/emulators.conf` now uses this.
> 2. **Eden prohibits AI-assisted contributions.** The repo's policy file
>    states AI/LLM use is strictly prohibited in their codebase and community
>    (code, docs, commits, issues). Since this project's patches are
>    AI-written, an upstream PR from us was off the table regardless —
>    submitting one would have violated their stated policy. Duplicating an
>    already-shipped feature was the bigger blocker, but this settles it.
>
> The original scoping below is preserved for reference; its "MVP" section
> describes, fairly closely, what Eden's own developers shipped in #3154.

## Why Eden is the right target

Of the emulators in our fleet, Eden (Switch, yuzu lineage) is the **only one
whose saves are unreachable without root** — they live in
`Android/data/dev.eden.eden_emulator/files/nand/user/save/`, which Android 11+
blocks every third-party app from reading. No sync tool can fix that from the
outside. **But the emulator itself can always read its own sandbox.** Building
the bridge *into* Eden is therefore the only non-root solution — and it
permanently fixes the problem for every Eden user, not just us.

RetroArch already has built-in cloud sync; PPSSPP and Dolphin can already use
public folders. Eden is where the gap is.

## The evidence this can actually get merged

1. **The demand is already filed.** Issue
   [eden-emulator/Issue-Reports#251](https://github.com/eden-emulator/Issue-Reports/issues/251)
   — *"[Feature] Custom saves location"* — asks for exactly this: the requester
   wants to sync saves across devices with Syncthing but can't reach
   `Android/data`, and doesn't want to root. It cites Azahar and PPSSPP as
   precedent. Unanswered as of research date → open opportunity.
2. **The machinery already exists in the codebase.** Commit
   [`33d36ded28` — "Add save import/export in UI"](https://git.eden-emu.dev/eden-emu/eden/commit/33d36ded28a709b72524fd8e532e5cc1df9f04bc)
   added a 226-line Kotlin fragment (`ImportExportSavesFragment.kt`) that
   already: zips the save tree, validates Title-ID folders by regex, and reads/
   writes through Android's SAF `DocumentFile` API. Our feature is largely a
   *re-orchestration of code that already shipped*.
3. **The project accepts outside code.** Main repo:
   [git.eden-emu.dev/eden-emu/eden](https://git.eden-emu.dev/eden-emu/eden/)
   (~28.8k commits), mirrors on [Codeberg](https://codeberg.org/eden-emu/eden)
   and [GitHub](https://github.com/eden-emulator/mirror) — the GitHub mirror
   literally says **"PRs welcome."**

## What to build (MVP: "Save Sync Folder")

**Not** a Google Drive/OneDrive OAuth client inside the emulator — that adds
network dependencies, token storage, and security surface that maintainers of
an emulator would rightly reject. Instead, the smallest feature that solves the
whole problem:

> **A user-chosen "save sync folder" (picked via SAF, e.g.
> `/storage/emulated/0/EdenSaves`) that Eden automatically mirrors its saves
> into on pause/exit, and re-imports from (newer-wins) on launch.**

Once saves exist in a public folder, *any* sync tool — Syncthing, Round Sync,
rclone, our `ecs` — handles the cloud leg. Eden stays network-free. This is
exactly the shape of feature #251 asks for, with auto-sync on top.

### Behavior spec
- Setting in Home Settings: "Save sync folder" → SAF directory picker →
  persist URI permission.
- `onPause`/emulation-stop: export save tree → sync folder (per-title
  subfolders, plain files — *not* one zip, so external tools can diff/sync
  incrementally).
- App launch (and before emulation start): compare per-file modtimes; copy
  newer files inward. Never delete; on conflict keep both
  (`<name>.conflict-<timestamp>`).
- A manual "Sync now" row + "last synced" status line.
- Off by default; zero behavior change unless the user opts in.

### Files touched (all Android frontend, all Kotlin — no C++ core changes)
| File | Change |
|---|---|
| `src/android/.../fragments/ImportExportSavesFragment.kt` | extract reusable save-tree copy logic |
| new `SaveSyncManager.kt` | folder mirror + newer-wins merge + conflict copies |
| `HomeSettingsFragment.kt` | settings entries (pick folder / sync now / status) |
| `EmulationActivity`/lifecycle hook | trigger export on pause/stop, import on start |
| `strings.xml` | UI strings |

### Effort estimate
- Competent Kotlin dev: **3–6 days** including testing.
- Us (Claude writes the Kotlin, CI builds it): the patch is writable now; the
  cost is the **build/test loop** — Eden is a huge C++/Kotlin hybrid; even
  Kotlin-only changes require building the full APK (Android SDK + NDK +
  CMake + Vulkan deps). Practical route: fork the GitHub mirror, add a GitHub
  Actions workflow to produce APKs, sideload and test on one device.
- Upstreaming: open a thread referencing #251 first, ask maintainers if
  they'd take it, then PR. Fork-first, PR-second.

### Phase 2 (optional, higher rejection risk)
Direct WebDAV target for the sync folder (RetroArch precedent). Only attempt
after MVP lands and with maintainer buy-in.

## Risks — be clear-eyed
- **Legal climate.** Nintendo DMCA'd yuzu and its forks off GitHub; Eden
  survives on self-hosted infra. The project could be disrupted at any time,
  and contributors in this scene are typically pseudonymous. Contributing code
  is not itself unlawful, but attach whatever name you're comfortable with.
- **Maintainer bandwidth.** #251 is unanswered; the PR could sit. Mitigation:
  our fork's APK works for us regardless of merge status.
- **Path drift.** Package/paths verified 2026-07: saves at
  `Android/data/dev.eden.eden_emulator/files/nand/user/save/` per the Eden
  save-location guide. Re-verify against the build we fork.

## Recommended sequence
1. Keep the fleet running today with `ecs`/Round Sync (root devices cover Eden
   in the meantime).
2. Fork `eden-emulator/mirror` → branch `save-sync-folder`.
3. I write the Kotlin patch + GitHub Actions APK workflow.
4. Sideload to one device, verify with a real game save round-trip.
5. Open the upstream conversation referencing #251, offer the PR.

## Sources
- [Eden main repo (git.eden-emu.dev)](https://git.eden-emu.dev/eden-emu/eden/)
- [Codeberg mirror](https://codeberg.org/eden-emu/eden) · [GitHub mirror — "PRs welcome"](https://github.com/eden-emulator/mirror)
- [Issue #251 — Custom saves location](https://github.com/eden-emulator/Issue-Reports/issues/251)
- [Commit 33d36ded28 — Add save import/export in UI](https://git.eden-emu.dev/eden-emu/eden/commit/33d36ded28a709b72524fd8e532e5cc1df9f04bc)
- [Eden save file location guide](https://edenemulators.com/eden-emulator-save-file-location-android/)
- [Android Authority — Eden after the GitHub DMCA](https://www.androidauthority.com/eden-switch-emulator-dmca-3647342/)
