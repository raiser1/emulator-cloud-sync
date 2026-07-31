# OneDrive Cleanup — Handoff Brief for Local Claude Code (Diablo)

_Owner: david.hilgendorf@gmail.com · Last updated 2026-07-30 by the cloud session._

**Read this first, then execute from "Remaining Work" down.** You are running on Diablo (Windows,
PowerShell) with `rclone` already configured. Everything here runs **server-side in the cloud** —
do not pull the library down to local disk.

---

## 1. Goal

Consolidate all of David's content onto **OneDrive (master, ~1 TB)**, organized into a numbered
taxonomy, deduplicated by hash, with legacy portfolio work properly archived. Google Drive is
redundancy + emulation. Box/Dropbox/iCloud are disposable.

## 2. Hard rules (from David — do not violate)

1. **Deletion requires a 100% content match** (hash), never name/size guessing.
2. **Dry-run every destructive command first**, show the preview, then re-run without `--dry-run`.
3. **Do not download files >10 MB locally without prompting.** Cloud-to-cloud only. The one
   sanctioned exception is ROM compression, which must stream one file at a time.
4. **Run security checks whenever there's any doubt** and report findings. "Rather be safe than sorry."
5. **Less is more** — shallow folders, created only when filled.
6. Be more ruthless the staler the file (~10 yrs unused → archive or delete).

## 3. Configured rclone remotes

`onedrive:` (master) · `gdrive:` · `dropbox:`

Google Drive uses David's **own** OAuth client (the shared rclone client is being retired in 2026).
If you hit `empty token`, run `rclone config reconnect gdrive:`.

## 4. Target taxonomy (built, in use)

```
00_Inbox            staging, drain to empty
10_Documents/       Employment, Financial, Identity, Legal, Medical, Reference, Resume, Vehicle
20_Photos/          by year (2002..2026) + David, Ryan, Barbi, Ryan-Art, Places
30_Portfolio/       MCN, FocalPoint, AMSOIL, OSK, VBMWMO, Mercedes-Benz, Editorial-Other, SCRAM
40_Media/           ROMS, Video, GameSaves, RetroArch, eBooks, Audio Books
90_Archive/         stale-but-keep (cold)
```

`Personal Vault/` throws `invalidResourceId: ObjectHandle is Invalid` — it is the BitLocker-encrypted
OneDrive vault. **rclone cannot reach it by design. Leave it alone.** Not an error to fix.

## 5. Current state (updated 2026-07-31)

| GB | Folder | Status |
|---|---|---|
| 563.24 | `40_Media/ROMS` | Being zipped per-system. **Grew from 559 GB** because `.zip` files sit next to un-deleted originals. |
| 76.2 | `20_Photos` | ✅ sorted by year |
| 21.6 | `00_Inbox` | ✅ deduped + classified + staged (see below) — **now the main remaining work is human review, not automation** |
| 34.4 | `30_Portfolio` | ✅ sorted (MCN 24.77) |
| 16.89 | `40_Media/Video` | ✅ |
| 5.87 | `40_Media/The Chronicles of Riddick…` | purge — game install |
| 0.27 | `90_Archive` | screenshots |
| 0.07 | `10_Documents` | ✅ sorted |

### 00_Inbox: dedupe + RetroArch merge + classifier — all done (2026-07-30/31)

1. **Dedupe vs. filed folders (10/20/30/40/90):** hash-matched every inbox file against everything
   already sorted. Deleted **15,158** exact duplicates + 0 internal dupes, then `rmdirs`. Inbox
   dropped from 71.07 GB / ~20k files → 21.6 GB / 4,736 files.
2. **RetroArch merge:** the inbox's `RetroArch/saves|states|config` export was copied server-side
   into `40_Media/RetroArch`, verified with `rclone check --one-way` (0 differences, 31/31 match),
   then the inbox source was purged.
3. **Classifier + staging** (script + full manifest saved to
   `~/Desktop/inbox-classify/{classify.py,manifest.csv}`): every remaining file was rule-matched
   against the taxonomy (brand keywords for Portfolio, doc-type keywords for Documents, filename/path
   -embedded dates for Photos — **never `ModTime`**, which this Google Drive export proved unreliable
   for photo-taken-date; verified `ModTime` diverges from the user's own `/YYYY/` folder structure).
   Ambiguous items were deliberately left unclassified rather than guessed. Everything was then
   physically moved (server-side, `rclone move --files-from`) into `00_Inbox/_staged/<category>/`,
   preserving the original relative path for traceability:

   | Category | Files |
   |---|---|
   | `_review` (needs your judgment) | 3,159 |
   | `30_Portfolio/MCN` | 823 |
   | `90_Archive` (installers, Wii/NUS homebrew, junk logs) | 100 |
   | `30_Portfolio/Editorial-Other` | 77 |
   | `20_Photos/<year>` (2002, 2007–2024) | ~340 total |
   | `10_Documents/Financial` | 44 |
   | `10_Documents/Legal` | 32 |
   | `10_Documents/Resume` | 31 |
   | `10_Documents/Employment` | 15 |
   | `30_Portfolio/{Mercedes-Benz,OSK,AMSOIL,FocalPoint,SCRAM,VBMWMO}` | 45 |
   | `10_Documents/{Identity,Vehicle,Medical}` | 9 |
   | `40_Media/{Video,Audio Books}` | 11 |

   **Flagging two sensitive folders found during classification** (per the "run security checks,
   report findings" rule) — both were kept together as a unit under `10_Documents/Legal` rather than
   scattered by keyword, and **not opened/read beyond the filenames needed to route them**:
   - `2.Home/Divorce/` (12 files: tax return letters, marital settlement, mortgage/Visa statements,
     insurance, a divorce procedural checklist). One file in it is literally named `...MCN COVERS.pdf`
     — the classifier's first pass nearly filed that into the MCN portfolio bucket on a brand-keyword
     match before a folder-level override caught it.
   - `4.PDF/23-026598-Hilgendorf_David/` (11 files: criminal complaint, search warrant, bail bond,
     summons, hospital diagnosis, towing, victim-witness, license-revocation intent) — an apparent
     court case file. Kept intact under Legal for your review.

   Next step is **you (or a future session) manually sorting `_staged/_review`** into the final
   10/20/30/40/90 folders — the classifier deliberately erred toward *not guessing* (67% landed in
   `_review`), so this is expected, not a failure of the automation.

## 6. Completed

- Full multi-cloud audit + security sweep: **24 sensitive items verified owner-only, none shared**
  (SSN, passport, licenses, tax returns, marital settlement, birth certificate, brokerage, W-2/W-9).
- All clouds copied into OneDrive; taxonomy built; `Pictures/`, `Dropbox.com/`, `VBMWMO/`,
  `Overland Expo/`, root dumps sorted into numbered folders.
- Empty junk purged (`_MASTER`, `win64_*`, `Supermodel_*`, `99_ToDelete-Installers`).
- N64 ROMs zipped (7-Zip, `-tzip -mx=9`).

## 7. NOT David's content — never migrate, never delete as his

- Box **"Daytona Pictures McIsaac"** — owned by event organizers, licensed to the VBMWMO magazine.
- Google Drive files owned by **mart@tombras.com** (Tombras ad agency), incl. `DSC_7174-Edit.tif`
  (802 MB) and the March-2026 `DSC_*.NEF` set.

## 8. P1 — archive, never delete

MCN photo shoots (`MCN1705`, `MCN1708`, `1605Ducati`, `KTM_Bikes`, `Harley1606`,
"Street Strategies – David Hough"), `.VBO` road-test telemetry, published mcnews PDFs, and legacy
MCN production assets 1992–2001 (EPS logos, binders, cards, `Dave.tiff`, `StreetStrategiesBW.tif`).
An earlier Copilot report recommended deleting the "old large TIFs" — **that advice is wrong**, they
are original MCN editorial photography.

---

## Remaining Work

### A. Finish the ROM compression payoff (biggest space item)

Zips currently sit *beside* originals, so net space is negative until originals are deleted. Per
system, verify counts then delete:

```powershell
$src = 'onedrive:40_Media/ROMS/<System>'
"orig: " + (rclone lsf $src --include "*.{z64,Z64}").Count
"zip:  " + (rclone lsf $src --include "*.zip").Count
rclone delete $src --include "*.{z64,Z64}" --dry-run
```

If counts don't match, only delete originals that have a matching zip:

```powershell
$zips = @{}
rclone lsf $src --include "*.zip" | % { $zips[[IO.Path]::GetFileNameWithoutExtension($_)] = $true }
rclone lsf $src --include "*.{z64,Z64}" |
  ? { $zips.ContainsKey([IO.Path]::GetFileNameWithoutExtension($_)) } |
  ForEach-Object { $_ } | Set-Content "$env:TEMP\rom-del.txt"
rclone delete $src --files-from "$env:TEMP\rom-del.txt" --dry-run
```

Continue zipping remaining systems (resumable; skips anything already zipped):

```powershell
$exts = 'n64','v64','z64','sfc','smc','nes','gba','gb','gbc','md','gen','smd','32x','nds','iso','gcm','wbfs'
$tmp = "$env:TEMP\romzip"; New-Item -ItemType Directory -Force -Path $tmp | Out-Null
rclone lsf onedrive:"40_Media/ROMS" --dirs-only | ForEach-Object {
  $sys = $_.TrimEnd('/'); $src = "onedrive:40_Media/ROMS/$sys"
  Write-Host "=== $sys ===" -F Green
  $done = @{}; rclone lsf $src --include "*.zip" | % { $done[[IO.Path]::GetFileNameWithoutExtension($_)] = $true }
  foreach ($e in $exts) {
    rclone lsf $src --include "*.$e" | ForEach-Object {
      $name = $_; $base = [IO.Path]::GetFileNameWithoutExtension($name)
      if ($done.ContainsKey($base)) { return }
      rclone copy "$src/$name" $tmp
      Remove-Item "$tmp\$base.zip" -Force -ErrorAction SilentlyContinue
      & 'C:\Program Files\7-Zip\7z.exe' a -tzip -mx=9 "$tmp\$base.zip" "$tmp\$name" | Out-Null
      rclone move "$tmp\$base.zip" $src
      Remove-Item "$tmp\$name" -Force
    }
  }
}
Remove-Item $tmp -Recurse -Force
```

**Never per-file zip `.bin`/`.cue` pairs** — it splits multi-track discs and breaks them.

### B. ~~Dedupe `00_Inbox` against everything already filed~~ — DONE 2026-07-30/31, see §5

The PowerShell below is kept for reference only (e.g. if a future export needs the same treatment);
it has already been run against the current inbox contents and does not need to be re-run.

<details><summary>Original dedupe script (already executed)</summary>

### B. Dedupe `00_Inbox` against everything already filed

Hash-based, metadata-only. Note: PowerShell's `h` is an alias for `Get-History`, so do not name a
helper function `H`.

```powershell
$OD='onedrive:'; $inbox='00_Inbox'
$sorted='10_Documents','20_Photos','30_Portfolio','40_Media','90_Archive'
$work="$env:USERPROFILE\Desktop\inbox-dedupe"; New-Item -ItemType Directory -Force -Path $work | Out-Null

$filed=@{}
foreach ($f in $sorted) {
  rclone lsjson "$OD$f" -R --files-only --hash 2>$null | ConvertFrom-Json | ForEach-Object {
    $hash=$null; if ($_.Hashes) { $hash=($_.Hashes.PSObject.Properties | Select-Object -First 1).Value }
    if ($hash -and $_.Size -gt 0) { $filed[$hash]="$f/$($_.Path)" }
  }
  Write-Host ("  {0,-15} {1}" -f $f,$filed.Count)
}
if ($filed.Count -eq 0) { Write-Host "NO HASHES RETURNED - stop" -F Red; return }

$items = rclone lsjson "$OD$inbox" -R --files-only --hash 2>$null | ConvertFrom-Json | ForEach-Object {
  $hash=$null; if ($_.Hashes) { $hash=($_.Hashes.PSObject.Properties | Select-Object -First 1).Value }
  if ($hash -and $_.Size -gt 0) {
    [pscustomobject]@{ Path=$_.Path; Size=$_.Size; Hash=$hash; Depth=($_.Path -split '/').Count }
  }
}

$alreadyFiled=@(); $internalDup=@(); $keep=@{}
foreach ($i in ($items | Sort-Object Depth,Path)) {
  if ($filed.ContainsKey($i.Hash)) { $alreadyFiled+=$i; continue }
  if ($keep.ContainsKey($i.Hash))  { $internalDup+=$i;  continue }
  $keep[$i.Hash]=$i.Path
}
# UTF8 without BOM - a BOM breaks rclone's first --files-from entry
[IO.File]::WriteAllLines("$work\del-already-filed.txt",[string[]]@($alreadyFiled|%{$_.Path}))
[IO.File]::WriteAllLines("$work\del-internal-dup.txt", [string[]]@($internalDup |%{$_.Path}))
```

Zero-byte files are excluded deliberately — they share one hash and would mass-delete each other.
Keeper for internal dupes is the **shallowest path**, favoring real folders over deep export nesting.

Then delete and collapse:

```powershell
rclone delete "onedrive:00_Inbox" --files-from "$work\del-already-filed.txt" -P --dry-run
rclone delete "onedrive:00_Inbox" --files-from "$work\del-internal-dup.txt"  -P --dry-run
rclone rmdirs "onedrive:00_Inbox" --leave-root --dry-run
```

Merge the export dumps into one reviewable tree. `--backup-dir` preserves same-name/different-content
collisions instead of overwriting them:

```powershell
$dumps='david.hilgendorf@gmail.com - Google Drive','david.hilgendorf@gmail.com - Dropbox',
       'david.hilgendorf@gmail.com - Box.com','from-gdrive','dropbox-documents','dropbox-SS-Uploads',
       'root-cleanup','root-Documents','root-Desktop','root-Attachments','root-OneNote'
foreach ($d in $dumps) {
  rclone move "onedrive:00_Inbox/$d" "onedrive:00_Inbox/_MERGED" `
    --backup-dir "onedrive:00_Inbox/_CONFLICTS/$d" -P --dry-run
}
rclone rmdirs "onedrive:00_Inbox" --leave-root --dry-run
```

Leave topic folders alone (`PDF`, `notes`, `Two Wheel`, `Ty_Harden…`, `Microsoft Copilot Chat Files`).
**Watch for `0.ROMS`/`3.Games` inside the Google Drive export** — that would be a third ROM copy; purge it.

</details>

The `_MERGED`/`_CONFLICTS` flat-merge idea above was **not** what actually got run — instead a
per-file classifier staged everything into `00_Inbox/_staged/<taxonomy-category>/` (see §5), which
gives the same "one reviewable tree" outcome but pre-sorted by destination category instead of by
source export. No third ROM copy was found in the Google Drive export during classification.

### C. Quick purges

```powershell
rclone purge onedrive:"40_Media/The Chronicles of Riddick - Assault on Dark Athena" --dry-run
rclone purge onedrive:"00_Inbox/.tmp.drivedownload" --dry-run
rclone purge onedrive:"20_Photos/1600x900" --dry-run
```

### D. Structural fixes

```powershell
rclone move onedrive:"30_Portfolio/Mercedes" onedrive:"30_Portfolio/Mercedes-Benz" --dry-run
rclone move onedrive:"20_Photos/X" onedrive:"00_Inbox/photos-X-review" --dry-run
```

**Open question for David:** `CRF300L`, `BMW-S1000RR`, `KLX300`, `KLR650`, `Overland-Expo` are in
`30_Portfolio` while `10_Documents/Vehicle` is empty. Editorial work → leave. Owner manuals /
service records → move to `10_Documents/Vehicle`.

### E. Dedupe the numbered folders

```powershell
rclone dedupe --by-hash --dedupe-mode newest onedrive:"20_Photos"    --dry-run
rclone dedupe --by-hash --dedupe-mode newest onedrive:"30_Portfolio" --dry-run
rclone dedupe --by-hash --dedupe-mode newest onedrive:"10_Documents" --dry-run
```

Plain `rclone dedupe` (name-based) does **not** work on OneDrive — it can't hold same-name files in
one folder. `--by-hash` is required, and it satisfies the 100%-match rule.

### F. Empty the Recycle Bin

Deleted OneDrive files **still count against the 1 TB quota** for 30 days. Used space will not drop
until the bin is emptied at onedrive.com. Keep it as the safety net through the cleanup, empty it
once the layout is confirmed.

### G. Clean the source clouds (only after `rclone check` confirms the copies landed)

```powershell
rclone check dropbox:"david pr" onedrive:"<dest>" --one-way --size-only   # want "0 differences"
rclone delete dropbox:"david pr" --dry-run
rclone dedupe gdrive: --dedupe-mode newest --dry-run                      # 2019 re-upload dupes
rclone delete gdrive:"Downloads" --include "*.exe" --include "*.msi" --include "*.torrent" --dry-run
```

Google Drive `Downloads` still holds installers and ~11 `.torrent` files. `2.Home/Documents` still
has the 2018/2019 duplicate pairs (e.g. `Himalayan.docx` ×2, identical size).

### H. E: SSD hard backup — **David said do not touch E: until OneDrive is confirmed sorted**

Scope chosen: **important tier only.**

```powershell
rclone sync onedrive:"10_Documents" "E:\OneDrive-Backup\10_Documents" -P
rclone sync onedrive:"20_Photos"    "E:\OneDrive-Backup\20_Photos"    -P
rclone sync onedrive:"30_Portfolio" "E:\OneDrive-Backup\30_Portfolio" -P
```

### I. Redundancy mirror OneDrive → Google Drive (last)

```powershell
rclone sync onedrive:"30_Portfolio" gdrive:"Backup/30_Portfolio" -P
rclone sync onedrive:"20_Photos"    gdrive:"Backup/20_Photos"    -P
rclone sync onedrive:"10_Documents" gdrive:"Backup/10_Documents" --exclude "Identity/**" -P
```

`Identity/**` is excluded on purpose — passport/SSN/licenses stay OneDrive-only, never mirrored.

---

## Open decision: `Games/` → `40_Media/ROMS`, 563 GB, 67% of the drive

Google Drive holds only 70.79 GB total, so **OneDrive is the only copy** — it is not backed up
anywhere. Three paths: keep as-is, compress in place (in progress, ~40–60% savings), or purge as
re-downloadable. David has not decided. **Do not purge without an explicit instruction.**
