# Scoping: RetroArch cloud sync — fleet setup today + the OneDrive gap

*Researched 2026-07-21 from the RetroArch master tree (sparse clone at
`C:\CLAUDE\forks\retroarch`, v1.22.2) and upstream PRs/issues. Sources at bottom.*

## Finding 1 — RetroArch now syncs saves natively, including Google Drive

The public docs are stale. The actual tree (`network/cloud_sync/`) contains
**six** cloud sync backends:

| Backend | File | Status |
|---|---|---|
| WebDAV | `webdav.c` | mature |
| **Google Drive** | `google_drive.c` | **added Feb 18 2026** (warmenhoven), actively maintained (last fix Jul 7 2026) |
| Amazon S3-compatible | `s3.c` | added ~Mar 2026 |
| SMB share | `smb.c` | present |
| iCloud / iCloud Drive | `icloud.m` / `icloud_drive.m` | Apple platforms |

And Android support was unblocked in June 2025 by the mbedTLS PR
([#17972](https://github.com/libretro/RetroArch/pull/17972), closing
[#16847](https://github.com/libretro/RetroArch/issues/16847)) — SSL-backed
cloud sync now builds on Android.

**Fleet impact (do this today, no third-party tool needed for RetroArch):**
1. Update RetroArch to the current stable (1.22.x) — use the official website
   APK or nightly, not the feature-stripped Play Store build.
2. Settings → Saving → **Cloud Sync** → enable, driver **google_drive** →
   follow the device-code authorization (it shows a code + URL to visit).
3. Turn on sync for saves/states/configs. Conflicts are non-destructive
   (neither side is overwritten; backups kept).
4. Verify in-app that the driver list shows google_drive on your build; if
   your build lacks it, grab a nightly.

RetroArch ROMs still come down via `ecs pull` / Round Sync — Cloud Sync
handles saves/states/configs/thumbnails/system, not ROM libraries. The
`retroarch` folder profile in `emulators.conf` remains as a fallback for
builds without Cloud Sync.

## Finding 2 — the real contribution gap: a OneDrive backend

There is **no `onedrive.c`**. Google Drive users are now served natively;
OneDrive users (i.e., half of David's stated setup) are not. This is the
highest-leverage upstream contribution in the entire space:

- **One PR covers every libretro core at once** — dozens of consoles.
- **The template sits in the same directory.** `google_drive.c` (1,640 lines
  of C) demonstrates the exact shape: OAuth *device-code* flow with polling
  task, refresh token persisted in settings
  (`configuration.c:1636`), obfuscated embedded client credentials, and a
  **5-function driver vtable** (`cloud_sync_driver.h`): `begin / end / read /
  update / free` + ident.
- **Microsoft's flow is actually simpler than Google's**: the MS identity
  platform device-code flow needs **no client secret** for public clients.
  Endpoints: `login.microsoftonline.com/consumers/oauth2/v2.0/devicecode` →
  poll `/token`; storage via Microsoft Graph
  (`/me/drive/special/approot` app folder, `PUT …/content` uploads, upload
  sessions only for >4 MB files — saves are far smaller).

### Work estimate
| Piece | Size |
|---|---|
| `network/cloud_sync/onedrive.c` (mirror gdrive structure) | ~1,400–1,800 lines C |
| Settings wiring (`configuration.c`, settings arrays, msg_hash labels, menu entries — mirror the gdrive commit set) | ~100–200 lines across ~6 files |
| Azure app registration (free) to own the `client_id` | admin task, not code |
| Testing on Android + desktop | the long pole |

A C developer: 1–2 weeks part-time. Harder than the Round Sync patch by an
order of magnitude — C, `-Wall` clean required, strict house style.

### Upstream strategy (sequencing matters)
1. **Buy-in first, code second.** Open an issue proposing the backend and ask
   whether the team wants it and who registers the Azure client_id (libretro
   must own the production one; a fork can use a personal registration).
   CC warmenhoven — author of webdav/gdrive/s3 and the Android TLS work; the
   cloud-sync area is actively theirs. Reference bounty issue
   [#6875](https://github.com/libretro/RetroArch/issues/6875).
2. No AI-use ban was found in RetroArch's
   [CONTRIBUTING.md](https://github.com/libretro/RetroArch/blob/master/CONTRIBUTING.md)
   (unlike Eden) — but re-verify at PR time and **disclose AI assistance in
   the PR regardless**. Their stated bars: consistent style, zero `-Wall`
   warnings, PRs via fork.
3. Only after a maintainer nod: write `onedrive.c` on a fork branch, test on
   one Android device + one desktop, then PR.

## Sources
- Local tree: `network/cloud_sync/*`, `network/cloud_sync_driver.h`, `configuration.c` @ v1.22.2
- [google_drive.c commit history](https://github.com/libretro/RetroArch/commits/master/network/cloud_sync/google_drive.c)
- [PR #17972 — Android mbedTLS (cloud sync on Android)](https://github.com/libretro/RetroArch/pull/17972) · [Issue #16847](https://github.com/libretro/RetroArch/issues/16847)
- [Cloud sync docs (stale re: backends)](https://docs.libretro.com/guides/retroarch-cloud-sync/) · [Bounty issue #6875](https://github.com/libretro/RetroArch/issues/6875)
- [CONTRIBUTING.md](https://github.com/libretro/RetroArch/blob/master/CONTRIBUTING.md)
