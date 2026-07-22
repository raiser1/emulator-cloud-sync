# Strategy: cloud sync in every emulator — the realistic path

*2026-07-22. Goal: ROM + save cloud unification across platforms/emulators,
by getting cloud-sync capability INTO the open-source projects themselves.*

## Why "integrating RetroArch's google_drive code" isn't literal

1. **Code doesn't port; design does.** `google_drive.c` is welded to
   RetroArch's HTTP task queue, settings arrays, and menu system. Dolphin,
   PPSSPP, ES-DE each have their own equivalents. What transfers is the
   architecture: OAuth *device-code* flow + refresh token in settings + a
   ~5-function sync vtable + REST calls.
2. **Licensing walls.** RetroArch is GPLv3. ES-DE is **MIT** — GPL code
   cannot be copied in without relicensing the project. Any permissively
   licensed emulator is off-limits for literal reuse.
3. **Per-project politics.** Eden bans AI contributions outright; Dolphin is
   famously strict; every project has its own bar. One PR per emulator,
   negotiated separately, re-implementing OAuth each time — that's the
   "too complicated" state, relocated upstream.

## The proven adoption model: rcheevos

RetroAchievements didn't PR achievement support into 20 emulators. They ship
**rcheevos** — a small, dependency-light, permissively-licensed C library —
and emulators (RetroArch, PPSSPP, DuckStation, melonDS, Flycast…) embed it.
The emulator supplies "read memory" hooks; the library does the rest.

**That is the template for cloud saves.** A tiny C library — call it
`libcloudsave` — that any emulator can vendor:

- Backends: Google Drive, **OneDrive** (device-code OAuth, no client secret),
  WebDAV; provider-agnostic vtable
- Emulator supplies: HTTP transport hooks (every emulator has an HTTP stack),
  token storage hooks, and "here are my save paths"
- Library supplies: OAuth flows, manifest/conflict logic (newest-wins,
  never-delete, conflict copies), folder mapping
- License: MIT/zlib so GPL *and* permissive projects can both embed it
- Written clean-room from the RetroArch driver's *design* (5-function vtable,
  device-flow pattern), not its code — no GPL contamination

## Phased plan

**Phase 1 — OneDrive backend in RetroArch** *(active)*
Proposal drafted (`onedrive-proposal-draft.md`); bug report #19244 filed
2026-07-22 establishing presence in the cloud-sync area. Post proposal →
maintainer buy-in → Claude writes `onedrive.c` mirroring `google_drive.c`
(same codebase = same GPL, direct reuse is fine HERE). Covers the family's
"primarily OneDrive" ask inside the one frontend that runs on Android,
Windows, and Linux.

**Phase 2 — extract the design into `libcloudsave`** *(next)*
Build the MIT library with Drive + OneDrive + WebDAV backends and a reference
CLI. Validate it by wiring it into one willing emulator first — best
candidates: PPSSPP (pragmatic maintainer, existing "Remote ISO" precedent for
network features) or melonDS. An emulator PR then becomes "vendor one small
lib + ~200 lines of glue," which is a far easier yes.

**Phase 3 — frontend-level sync for the holdouts (ES-DE)** *(later)*
ES-DE runs on Windows/Mac/Linux/Android and already knows every emulator's
save locations. A CloudSync-style feature there (using libcloudsave) covers
emulators that never adopt sync natively — EmuDeck CloudSync's value, but
cross-platform and built into the frontend everyone already uses. MIT license
means libcloudsave slots in cleanly where GPL code never could.

## Sequencing rule learned from Eden/RetroArch scoping
**Buy-in before code, disclosure always.** Propose in each project's channel
(issue/Discord), disclose AI assistance, get a maintainer nod, then write.
Personal forks remain the fallback where upstream declines.

## Family fleet interim
Until upstream lands: RetroArch built-in sync (working), EmuDeck CloudSync on
Bazzite, Round Sync/ecs for Android standalones, rclone on PCs — all against
the same Drive schema. The strategy above replaces these shims one merge at a
time; it does not block on them.
