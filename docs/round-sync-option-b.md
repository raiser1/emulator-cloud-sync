# Option B: Round Sync "Emulator Presets" fork — status & build guide

*Prepared 2026-07-21. Patch written and locally committed; NOT yet pushed
anywhere — waiting on the GitHub fork (see "Your steps" below).*

## What exists right now
- Local clone: `C:\CLAUDE\forks\round-sync` (upstream:
  [newhinton/Round-Sync](https://github.com/newhinton/Round-Sync), GPL-3.0,
  Java/Kotlin, ~2.3k stars — the maintained successor of RCX/rcloneExplorer).
- Branch **`emulator-presets`**, commit `04135b7` — 4 files, +117/−1:
  - new `Items/EmulatorPreset.kt` — 11 preset folder-pairs: PPSSPP (save data /
    states / system), RetroArch (saves / states / config), Dolphin (GC / Wii /
    states / config), Eden (`/storage/emulated/0/EdenSaves` bridge folder —
    requires Eden's Settings → Save Data Directory pointed there, see
    `eden-fork-scoping.md`).
  - `TaskActivity.kt` — "Use emulator preset" menu item on the new-task screen;
    picking one pre-fills title, local path, and suggested remote subpath under
    `EmulatorSync/saves/…`. User still picks remote, direction, filters.
  - new `menu/task_activity_menu.xml`, 3 new strings in `strings.xml`.
- The commit message discloses AI co-authorship (`Co-Authored-By: Claude`).

## How you get an installable APK (no compiler on your PC)
Round Sync ships a GitHub Actions workflow (`.github/workflows/android.yml`)
that builds per-ABI APKs on demand:

1. **Fork** [newhinton/Round-Sync](https://github.com/newhinton/Round-Sync) on
   your GitHub (one click).
2. Tell Claude the fork exists → the `emulator-presets` branch gets pushed to
   it (credentials are already cached on the PC).
3. On your fork: **Actions** tab → enable workflows → pick **Android CI** →
   **Run workflow** → select branch `emulator-presets`.
4. Wait ~15–30 min (it compiles rclone from Go source). Download the
   `nightly-arm64` (or `nightly-universal`) artifact, unzip, sideload the APK.

**Caveats:** the CI APK is debug-signed — it will NOT install over a Play/
F-Droid copy of Round Sync (uninstall that first). Artifact downloads require
being logged into GitHub.

## Automation reality (for "sync when emulator closes")
Round Sync's built-in triggers are time-based only (schedule/interval). BUT
tasks can be started externally by intent (`ShortcutServiceActivity`,
action `START_TASK`, extra `task` = task id) — so MacroDroid/Tasker "app
closed → send intent" gives event-driven sync today, same pattern as
AUTOMATION.md.

## Upstreaming plan (transparency required)
1. Check Round Sync's CONTRIBUTING/README for any AI-contribution policy
   (none was found during scoping, but re-verify at PR time — Eden taught us
   this lesson).
2. Open the PR with explicit disclosure that the patch is AI-written and
   human-reviewed; the commit trailer already says so. Let the maintainer
   decide — no silent AI contributions.
3. Expect review notes: preset labels could move to string resources for
   translation; the Eden bridge-folder entry needs its rationale explained
   (link Eden PR #3154).

## Honest status
The Kotlin is hand-reviewed against the project's existing patterns but has
**never been compiled or run** — first CI build may surface issues; runtime
behavior (preset surviving remote-spinner selection) is reasoned, not observed.
