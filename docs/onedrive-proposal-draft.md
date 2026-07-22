# Draft: OneDrive backend proposal for RetroArch (for David to post)

*Per RetroArch's CONTRIBUTING.md, larger features should be raised on the
libretro Discord first. Recommended flow: post the GitHub issue (durable,
linkable), then drop the short version in Discord with a link.*

---

## GitHub issue draft

**Repo:** `libretro/RetroArch` → Issues → New issue

**Title:** `[Feature Proposal] OneDrive cloud sync backend (companion to google_drive.c)`

**Body:**

> Cloud Sync recently gained a Google Drive backend (`network/cloud_sync/google_drive.c`, Feb 2026) alongside WebDAV/S3/SMB/iCloud, and #17972 unlocked SSL-backed sync on Android. OneDrive is one of the largest consumer clouds and currently has no backend — OneDrive users are the biggest unserved group left.
>
> **Proposal:** `network/cloud_sync/onedrive.c`, structured directly on `google_drive.c`:
> - Microsoft identity platform **device-code flow** — public client, notably *no client secret needed* (simpler than the Google flow)
> - refresh token persisted in settings, same pattern as `google_drive_refresh_token`
> - storage via Microsoft Graph **app folder** (`/me/drive/special/approot`) so RetroArch only sees its own folder; simple `PUT …/content` uploads (save files are small; upload sessions only needed >4 MB)
> - same 5-function `cloud_sync_driver_t` vtable, C89, `-Wall` clean, house style
>
> **Questions before any code is written:**
> 1. Is this a backend the team wants?
> 2. Who registers/owns the (free) Azure app `client_id` for official builds? A fork can use a personal registration for development, but production should be libretro-owned, like the Google credentials.
> 3. Any preference on app-folder scope (`Files.ReadWrite.AppFolder`) vs. broader drive access?
>
> I can have the implementation contributed and tested on Android + desktop. Transparency note: the implementation would be developed with AI assistance (Claude), with human review and on-device testing — flagging this up front; happy to discuss.
>
> CC @warmenhoven (author of the webdav/gdrive/s3 backends and the Android TLS work). Related: #6875 (native cloud saving bounty).

---

## Discord short version (post in the appropriate dev channel, link the issue)

> Proposing a OneDrive cloud sync backend modeled on google_drive.c — MS device-code flow (no client secret), Graph app-folder storage, same driver vtable. Opened <issue link> with the details + open questions (mainly: who owns the Azure client_id for official builds?). Would love a signal on whether it's wanted before code gets written.

---

## After posting
- If a maintainer signals interest → Claude writes `onedrive.c` on a fork
  branch (C89, mirroring gdrive structure), CI-builds it, and you test on one
  Android device before the PR.
- If rejected or ignored for a long while → the fork can still carry it for
  personal use (GPLv3 permits this), but upstream-first remains the goal.
