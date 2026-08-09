# CLAUDE.md — emulator-cloud-sync

`ecs`: bash wrapper over `rclone` for two-way emulator save/config sync + one-way ROM pull. Runs in **Termux on Android**.

## Layout
- `bin/ecs` — the whole program. Single bash file, no deps beyond rclone + coreutils.
- `profiles/emulators.conf` — sourced by `ecs`. Only file users edit. Declares profiles via the `profile` function.
- `README.md` setup/daily use · `AUTOMATION.md` hands-free triggers · `docs/` scoping + upstream drafts.

## Hard invariants — do not weaken
- **ROMs are copy-only.** `rclone copy`, never `sync`/`bisync`, never a delete flag. ROMs are immutable.
- **Saves keep every `BISYNC_FLAGS` rail**: `--conflict-resolve newer`, `--conflict-loser pathname`, `--max-delete 25`, `--resilient --recover`. Removing any one lets a stale device destroy progress.
- **Nothing is hard-deleted.** Conflict losers are kept as `<name>.conflict1`.
- `root 1` profiles must be *skipped with a message* on `DEVICE_ROOTED=0`, never fail. Android 11+ forbids non-root reads of another app's `Android/data` — no workaround exists; don't invent one.
- Shebang stays `#!/data/data/com.termux/files/usr/bin/bash`. LF endings (enforced by `.gitattributes`).
- Never commit `.ecs/` or `*.log`.

## Conventions
- POSIX-ish bash, `set -u`. Output via `say/ok/warn/err/head` helpers — don't add new color codes.
- Colon separates multi-path fields; Android paths never contain `:`.
- New emulator = a `profile` block in the conf, not code in `bin/ecs`.
- Paths in conf are *defaults*; `ecs list` marks them ✓/✗. Never assert a path exists — say "verify with `ecs list`".

## Verifying
No Android/rclone here. Check with `bash -n bin/ecs` and `shellcheck`. Do not claim runtime behavior was tested.

## User rules (ADDRULE)
Rules the user has explicitly asked to persist. **Convention:** whenever the user prefixes a
message with `ADDRULE:`, append the stated rule to this list (and commit it) so it carries across
sessions.

1. **Browser-first execution.** Check whether a task can be done via the browser / set up locally
   before handing the user manual instructions. _(Boundary: from a cloud session the only browser
   driven directly is this container's unauthenticated one; the user's authenticated browser is
   reached via **Claude for Chrome** — route browser work there with a ready prompt.)_
2. **`ADDRULE:` → persist here.** Any time the user prefixes an instruction with `ADDRULE:`, add
   that rule to this list (and commit/push it) so it persists across sessions.

---

Token discipline lives in the global `~/.claude/CLAUDE.md` (source: `raiser1/station`
→ `claude-global/`). Do not restate it here. Maintain this file with
`/compress-claude-md` (runs weekly, Wed AM CST); protected rules are listed in
`.claude/protected-rules.md`.
