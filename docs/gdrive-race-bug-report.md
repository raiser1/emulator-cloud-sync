# Bug report draft: google_drive Cloud Sync folder-creation race

**Target:** github.com/libretro/RetroArch/issues/new (bug template)

---

**Title:** `Cloud Sync (google_drive): concurrent folder creation creates duplicate same-name folders; files then split between twins and sync stalls`

**Body:**

### Description
The google_drive cloud sync backend creates **duplicate sibling folders with
identical names** when multiple uploads targeting the same missing folder run
concurrently. Google Drive permits same-named siblings, so both "check
missing → create" calls succeed. Because folder lookup requests only one
match (`&fields=files(id)&pageSize=1` in `gdrive_folder_lookup`), subsequent
syncs non-deterministically resolve to either twin — files end up split
across both, the manifest disagrees with whichever twin is consulted, and
sync sessions stall (persistent "Cloud Sync in progress 0%").

### Evidence (Drive API `createdTime` metadata from an affected account)
Duplicate twins were created **41–148 ms apart**, on three separate dates,
including with the 2026-07-22 nightly — so the race is alive in master:

| Folder (parent) | Twin 1 created | Twin 2 created | Δ |
|---|---|---|---|
| `config` (RetroArch/) | 2026-06-23T10:57:26.008Z | 2026-06-23T10:57:26.049Z | 41 ms |
| `Azahar` (saves/) | 2026-06-24T19:53:13.860Z | 2026-06-24T19:53:13.903Z | 43 ms |
| `Mupen64Plus-Next` (config/) | 2026-07-22T05:08:51.723Z | 2026-07-22T05:08:51.849Z | 126 ms |
| `remaps` (config/) | 2026-07-22T05:09:02.651Z | 2026-07-22T05:09:02.799Z | 148 ms |

Observed consequences on the same account: `FinalBurn Neo`, `Mesen`,
`melonDS DS`, `Mupen64Plus-Next` core config folders exist in **both**
`config` twins with contents split between them; sync sessions stall at 0%;
one crash occurred immediately after completing the OAuth device flow on
Android (1.22.2 nightly 2026-07-22, aarch64) — plausibly the same
manifest/folder-tree confusion, though not yet isolated.

### Environment
- RetroArch 1.22.2 nightly (2026-07-22), Android aarch64, google_drive backend
- Duplicates also created by late-June 2026 nightlies (see table)
- Sync: Saves + Configuration Files enabled (initially also Thumbnails/System)

### Reproduction
1. Fresh Drive account (or empty RetroArch folder), google_drive backend
2. Enable sync for saves + configs with content across many per-core subfolders
3. Trigger the first "Sync Now" so many uploads with missing parent folders
   run concurrently
4. Inspect Drive: duplicate same-named sibling folders appear (ms apart)

### Suggested direction
Serialize folder resolution/creation (single-flight per path via the folder
cache added in `cloud sync: allocate the drive folder cache on first use`),
or pre-resolve/create the folder tree before enqueueing file transfers.
Detecting existing same-name siblings during lookup (pageSize>1 + warn/merge)
would also make the backend self-healing for already-affected accounts.

Happy to test patches on affected devices.

*Transparency: this report was investigated and drafted with AI assistance
(Claude); the evidence is from my own Google Drive account.*
