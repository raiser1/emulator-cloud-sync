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

---

# Token discipline

Context quality degrades as the window fills ("context rot"); the large window is insurance, not a target. Apply to every session:

- **Compact at ~60%**, manually. Auto-compact fires near the limit — exactly when the summary is worst.
- **Delegate wide searches to subagents.** A subagent burns its own context and returns only the report. Use it for "find every place that X", not for a known-file edit.
- **Read narrowly.** Grep/Glob to locate, then read the specific range. Don't cat whole files to "get oriented"; don't re-read a file already in context; don't re-read after your own successful edit.
- **`/rewind` beats arguing.** A wrong turn is cheaper to reset than to correct across several turns. (Rewind = code+conversation; "conversation only" keeps the code.)
- **Chain sessions.** At a natural boundary: summarize state → `/clear` → paste summary as the first message of the new session.
- **Markdown in, not HTML/PDF.** Converted markdown runs ~85–90% cheaper for the same content.
- **Smallest model that clears the bar.** Renames, formatting, mechanical edits don't need Opus.
- **Batch independent tool calls** into one turn.
- **No preamble, no recap, no narration.** Answer, then stop. Skip "Great question", skip restating the request, skip summarizing a diff the user can see.

Maintain this file with `/compress-claude-md` (runs weekly, Wed AM CST).
