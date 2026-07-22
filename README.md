# Emulator Cloud Sync (`ecs`)

Keep your Android emulators' **saves & configs** in sync two-ways with **Google
Drive or OneDrive**, and **pull ROMs down on demand** — so you store games once
in the cloud and access them from any device, with saves that follow you.

It's a small, safe wrapper around [`rclone`](https://rclone.org) running in
[Termux](https://termux.dev). rclone is the "one interface, any cloud" engine —
that's how you get *both* Google Drive and OneDrive from the same commands.

---

## Why this design (the honest version)

- **Saves sync two-ways and safely.** Uses `rclone bisync` with conflict rails:
  a newer save wins, the older one is *kept* (never deleted) as a `.conflict`
  copy, and the run aborts if it would delete more than 25 files. A stale device
  can't silently wipe your progress.
- **ROMs pull one-way** (cloud → device, copy-only). ROMs never change, so this
  is simple and fast, and your emulator reads them at **full local speed** — no
  laggy streaming, no random-seek-over-network problems.
- **Mixed root, handled.** Emulators that store saves in a public folder work
  with **no root**. Emulators that hide saves in `Android/data/<pkg>` (Eden,
  Citra, Yuzu-forks) need **root** — on a non-rooted device those are skipped
  with a clear message; on a rooted device a `su` staging bridge syncs them.

### The one hard limit to know up front
On Android 11+, a non-root app **cannot read another app's `Android/data`
folder — period.** So for non-rooted devices, point these emulators at a public
folder in their own settings (one-time):

| Emulator | Setting to change | Point it to |
|---|---|---|
| RetroArch | Settings → Directory → Saves / Save States | `/storage/emulated/0/RetroArch/...` |
| Dolphin | Config → General → User Directory | `/storage/emulated/0/Dolphin` |
| PPSSPP | (already public — nothing to do) | `/storage/emulated/0/PSP` |

Eden/Yuzu-forks and Citra can't relocate off `Android/data`, so those require a
rooted device.

---

## One-time setup (per device)

### 1. Install Termux + rclone
Install **Termux** from [F-Droid](https://f-droid.org/packages/com.termux/)
(the Play Store build is outdated — don't use it). Then:

```bash
pkg update && pkg install rclone git
termux-setup-storage        # grant storage access when prompted
```

### 2. Connect your cloud (this is the OAuth step rclone handles for you)
```bash
rclone config
```
- `n` (new remote) → name it **`gdrive`** → choose **Google Drive** → accept the
  defaults → when it asks to authenticate, say **yes** and a browser opens for
  you to log in. Done.
- Repeat for OneDrive if you want it: name it **`onedrive`** → choose
  **Microsoft OneDrive**.

Verify:
```bash
rclone lsd gdrive:
```

### 3. Install this toolkit
```bash
cd ~
git clone <your copy of this folder> emulator-cloud-sync   # or copy it over
cd emulator-cloud-sync
# if you copied files from Windows, fix line endings once:
pkg install dos2unix && dos2unix bin/ecs profiles/emulators.conf
chmod +x bin/ecs
ln -sf "$PWD/bin/ecs" $PREFIX/bin/ecs      # so you can just type `ecs`
```

### 4. Tell it about THIS device
Edit `profiles/emulators.conf`:
- Set `CLOUD_REMOTE="gdrive"` (or `"onedrive"`).
- Set `DEVICE_ROOTED=1` on rooted devices, `0` otherwise.
- Then check your paths:
```bash
ecs list
```
Every save/config path shows ✓ (found) or ✗ (fix it). Correct any ✗ paths in
the conf. Root paths show `?` (can't be checked without invoking root).

---

## Daily use

```bash
ecs sync              # two-way sync ALL emulators' saves+configs
ecs sync ppsspp       # just one
ecs pull              # download any new ROMs from the cloud to this device
ecs pull dolphin      # just one system's ROMs
ecs status            # dry-run: show what WOULD change, touch nothing
```

Situational:
```bash
ecs push              # force device -> cloud (before you put a device away)
ecs fetch             # force cloud -> device (a brand-new device)
ecs resync            # rebuild the two-way baseline (see note below)
```

### First-ever sync of a save set
The very first `ecs sync` for an emulator has no baseline, so it auto-runs a
`resync` to establish one. **`--resync` makes the cloud and device match by
preferring whichever side you run it from.** So: run your **first** sync on the
device that already has the good saves. After that, `ecs sync` is fully two-way.

---

## Making it *not* cumbersome — auto-sync on emulator open/close
See **[AUTOMATION.md](AUTOMATION.md)** for one-tap widgets and hands-free
"sync when I launch/quit an emulator" using Termux:Tasker or MacroDroid. That's
the piece that turns this into "cloud saves just happen."

---

## Uploading your ROM library once
From any device (or your PC with rclone):
```bash
rclone copy /path/to/psp-games   gdrive:EmulatorSync/roms/psp    --progress
rclone copy /path/to/switch-games gdrive:EmulatorSync/roms/switch --progress
```
Then `ecs pull` on each device grabs what it's missing.

## Safety & recovery
- Nothing is ever hard-deleted by `pull` (copy-only).
- `sync` won't proceed past a mass-deletion (`--max-delete 25`).
- Conflicts are preserved as `<name>.conflict1` etc. — you keep both.
- Logs: `~/.ecs/logs/`. Run `ecs status` anytime to preview changes safely.
